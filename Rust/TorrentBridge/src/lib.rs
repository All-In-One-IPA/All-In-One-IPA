//! Embedded BitTorrent engine for iOS.
//!
//! This is a direct static-library bridge to librqbit. No HTTP server, no
//! qBittorrent process, no remote API. Files stay in the app Documents folder.
//! Every FFI function returns an owned JSON C string freed by aio_torrent_free.

use std::{
    ffi::{CStr, CString},
    os::raw::c_char,
    path::PathBuf,
    sync::{Arc, Mutex, OnceLock},
};

use librqbit::{
    api::{ApiTorrentListOpts, TorrentIdOrHash},
    AddTorrent, AddTorrentOptions, Api, Session, SessionOptions, SessionPersistenceConfig,
};
use serde_json::{json, Value};
use tokio::runtime::{Builder, Runtime};

struct Engine {
    runtime: Runtime,
    api: Api,
}

static ENGINE: OnceLock<Mutex<Option<Arc<Engine>>>> = OnceLock::new();

fn engine() -> &'static Mutex<Option<Arc<Engine>>> {
    ENGINE.get_or_init(|| Mutex::new(None))
}

fn c_text(value: *const c_char) -> Result<String, String> {
    if value.is_null() {
        return Err("Пустой аргумент библиотеки".into());
    }
    let value = unsafe { CStr::from_ptr(value) };
    value
        .to_str()
        .map(|s| s.to_owned())
        .map_err(|_| "Не удалось прочитать UTF-8".into())
}

fn ffi_result(operation: impl FnOnce() -> Result<Value, String>) -> *mut c_char {
    let response = match operation() {
        Ok(data) => json!({"ok": true, "result": data}),
        Err(error) => json!({"ok": false, "error": error}),
    };
    let text = response.to_string().replace('\0', "");
    CString::new(text)
        .expect("JSON must not contain interior NUL")
        .into_raw()
}

fn with_engine(action: impl FnOnce(&Engine) -> Result<Value, String>) -> Result<Value, String> {
    // Never hold the global mutex while resolving magnet metadata or connecting
    // to trackers. Those operations can take seconds; the UI must remain able
    // to fetch statistics, pause downloads and show peer diagnostics.
    let current = {
        let guard = engine().lock().map_err(|_| "Torrent engine mutex unavailable")?;
        Arc::clone(guard.as_ref().ok_or("Сначала запусти торрент-движок.")?)
    };
    action(&current)
}

#[no_mangle]
pub extern "C" fn aio_torrent_initialize(folder: *const c_char) -> *mut c_char {
    ffi_result(|| {
        let folder = c_text(folder)?;
        if folder.trim().is_empty() {
            return Err("Не указана локальная папка загрузок".into());
        }
        let path = PathBuf::from(folder);
        std::fs::create_dir_all(&path).map_err(|e| e.to_string())?;
        let state_path = path.join(".rqbit-session");
        std::fs::create_dir_all(&state_path).map_err(|e| e.to_string())?;

        let mut guard = engine().lock().map_err(|_| "Torrent engine mutex unavailable")?;
        if guard.is_some() {
            return Ok(json!({"status": "already_started"}));
        }
        let runtime = Builder::new_multi_thread()
            .worker_threads(4)
            .enable_all()
            .build()
            .map_err(|e| format!("Tokio: {e}"))?;

        let mut options = SessionOptions::default();
        options.fastresume = true;
        options.ipv4_only = true;
        options.disable_local_service_discovery = true;
        options.peer_limit = Some(120);
        options.runtime_worker_threads = Some(4);
        options.persistence = Some(SessionPersistenceConfig::Json {
            folder: Some(state_path),
        });
        let session = runtime
            .block_on(Session::new_with_opts(path, options))
            .map_err(|e| format!("librqbit: {e:#}"))?;
        *guard = Some(Arc::new(Engine {
            runtime,
            api: Api::new(session, None),
        }));

        Ok(json!({"status": "started", "engine": "librqbit 9.0.0"}))
    })
}

#[no_mangle]
pub extern "C" fn aio_torrent_add_magnet(magnet: *const c_char) -> *mut c_char {
    ffi_result(|| {
        let magnet = c_text(magnet)?;
        if !(magnet.starts_with("magnet:?xt=urn:btih:")
            || magnet.starts_with("magnet:?xt=urn:btmh:"))
        {
            return Err("Нужна настоящая magnet-ссылка (btih или btmh).".into());
        }
        with_engine(|e| {
            let options = AddTorrentOptions {
                overwrite: true,
                ..Default::default()
            };
            let added = e
                .runtime
                .block_on(e.api.api_add_torrent(AddTorrent::from_url(magnet), Some(options)))
                .map_err(|err| format!("{err:#}"))?;
            serde_json::to_value(added).map_err(|err| err.to_string())
        })
    })
}

#[no_mangle]
pub extern "C" fn aio_torrent_add_file(path: *const c_char) -> *mut c_char {
    ffi_result(|| {
        let path = c_text(path)?;
        let bytes = std::fs::read(path).map_err(|err| err.to_string())?;
        if bytes.is_empty() || bytes.len() > 16 * 1024 * 1024 {
            return Err("Недопустимый размер .torrent-файла (0–16 МБ).".into());
        }
        with_engine(|e| {
            let options = AddTorrentOptions {
                overwrite: true,
                ..Default::default()
            };
            let added = e
                .runtime
                .block_on(e.api.api_add_torrent(AddTorrent::from_bytes(bytes), Some(options)))
                .map_err(|err| format!("{err:#}"))?;
            serde_json::to_value(added).map_err(|err| err.to_string())
        })
    })
}

#[no_mangle]
pub extern "C" fn aio_torrent_list() -> *mut c_char {
    ffi_result(|| {
        with_engine(|e| {
            serde_json::to_value(e.api.api_torrent_list_ext(ApiTorrentListOpts {
                with_stats: true,
            }))
            .map_err(|err| err.to_string())
        })
    })
}

/// Live session diagnostics: peer counts, connection errors, DHT routing.
/// Useful for distinguishing a badly seeded torrent from an app/network issue.
#[no_mangle]
pub extern "C" fn aio_torrent_diagnostics() -> *mut c_char {
    ffi_result(|| {
        with_engine(|e| {
            let session = serde_json::to_value(e.api.api_session_stats())
                .map_err(|err| err.to_string())?;
            let dht = e.api.api_dht_stats()
                .ok()
                .and_then(|stats| serde_json::to_value(stats).ok());
            Ok(json!({
                "session": session,
                "dht": dht,
                "peer_limit": 120,
                "runtime_workers": 4,
            }))
        })
    })
}

#[no_mangle]
pub extern "C" fn aio_torrent_pause(id: u64) -> *mut c_char {
    ffi_result(|| {
        with_engine(|e| {
            e.runtime
                .block_on(e.api.api_torrent_action_pause(TorrentIdOrHash::Id(id as usize)))
                .map_err(|err| format!("{err:#}"))?;
            Ok(json!({"id": id, "state": "paused"}))
        })
    })
}

#[no_mangle]
pub extern "C" fn aio_torrent_resume(id: u64) -> *mut c_char {
    ffi_result(|| {
        with_engine(|e| {
            e.runtime
                .block_on(e.api.api_torrent_action_start(TorrentIdOrHash::Id(id as usize)))
                .map_err(|err| format!("{err:#}"))?;
            Ok(json!({"id": id, "state": "running"}))
        })
    })
}

#[no_mangle]
pub extern "C" fn aio_torrent_remove(id: u64, delete_files: bool) -> *mut c_char {
    ffi_result(|| {
        with_engine(|e| {
            if delete_files {
                e.runtime
                    .block_on(e.api.api_torrent_action_delete(TorrentIdOrHash::Id(id as usize)))
                    .map_err(|err| format!("{err:#}"))?;
            } else {
                e.runtime
                    .block_on(e.api.api_torrent_action_forget(TorrentIdOrHash::Id(id as usize)))
                    .map_err(|err| format!("{err:#}"))?;
            }
            Ok(json!({"id": id, "removed": true, "deleted_files": delete_files}))
        })
    })
}

#[no_mangle]
pub extern "C" fn aio_torrent_shutdown() -> *mut c_char {
    ffi_result(|| {
        let current = {
            let mut guard = engine().lock().map_err(|_| "Torrent engine mutex unavailable")?;
            guard.take()
        };
        // Outstanding requests retain Arc<Engine> until completion. Drop the
        // owner here without blocking the UI on magnet/peer network I/O.
        drop(current);
        Ok(json!({"status": "stopped"}))
    })
}

/// C strings are owned by Rust and must be freed exactly once by Swift.
#[no_mangle]
pub extern "C" fn aio_torrent_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe { drop(CString::from_raw(ptr)) };
    }
}
