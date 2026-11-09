# All-In-One

A personal, modular iOS utility app built with SwiftUI. One place for network tools, remote access, media, downloads, and everyday utilities.

> **Status: functional minimums under development.** The next build provides native operations for every module. Each remains an early MVP, not a complete production-grade client. Some actions depend on external servers and are limited by iOS foreground execution.

## Interface

- **Home** — overview, featured module and shortcuts
- **Modules** — searchable categories and development statuses
- **Activity** — reserved for future connection and task history
- **Devices** — reserved for SSH, SFTP and monitoring connections
- **Settings** — light / dark / system appearance and project information

## Roadmap

| Module | State |
| --- | --- |
| tg-ws-proxy (port of [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy)) | Planned |
| SSH & SFTP | Planned |
| DNS profile builder | Planned |
| Media player | Planned |
| Torrent downloads | Research |
| Mail client | Planned |
| Custom keyboard extension | Beta: local RU/EN keyboard, no Full Access |
| Beszel dashboard | Planned |
| Network diagnostics | Planned |
| Archive manager | Planned |

The planned tg-ws-proxy integration specifically refers to **Flowseal/tg-ws-proxy**, a local Telegram MTProto proxy. It is **not** a Telemt relay. Background execution on iOS requires device testing and is not promised.

## Module foundations

Each non-keyboard module has a typed configuration, shared UI and its own **real** action handler in `App/Modules/<Module>/*ActionView.swift`. Implemented minimums:

| Module | Implemented minimum | Deferred |
| --- | --- | --- |
| Telegram / tg-ws-proxy | Local foreground SOCKS5/TCP relay | Flowseal MTProto/WebSocket and background service |
| SSH / SFTP | Password SSH command execution and read-only remote folder listing (Citadel) | Host-key pinning, full terminal and file transfers |
| DNS Studio | Generate and export valid DoH/DoT `.mobileconfig` profiles | Profile signing and automated installation |
| Media | Import audio/video from Files and play via AVPlayer | Advanced metadata, playlists |
| Torrent | Remote qBittorrent HTTPS login, list tasks, add magnet | On-device P2P engine |
| Mail | IMAPS/TLS inbox counts and native iOS mail composer | Message browsing, built-in SMTP |
| Keyboard | Real offline RU/EN keyboard extension | Suggestions and gestures |
| Beszel | PocketBase login and systems listing | Detailed charts/real-time updates |
| Network Lab | HTTP HEAD, DNS and TCP diagnostics | Packet capture, history |
| Archives | ZIP import, extract, create and export | 7z, TAR |
| Server Tools | Authenticated JSON HTTPS API requests | Docker-specific API client/UI |
| Automation | Save, run and delete manual local actions | Background triggers and App Intents |

**Security:** Sensitive secrets do not enter `UserDefaults`. Server API tokens can be stored in device-only Keychain. The SSH experimental connection currently accepts host keys without authentication of the host — **do not use it on untrusted networks** until known-host verification is implemented. The SOCKS5 relay is unauthenticated and is intended to listen on device loopback only; it does not implement the Flowseal protocol. Third-party services run only when triggered by the user.


## Keyboard

AllInOneKeyboard is a separate `com.apple.keyboard-service` app extension embedded inside the IPA. It can insert and delete text in third-party text fields, switch between Russian and English, use Shift/Caps Lock and symbol layouts, and change keyboard appearance. It does not request Full Access, App Groups or network access.

To enable on the iPhone: **Settings → General → Keyboard → Keyboards → Add New Keyboard → All-In-One Keyboard**. In supported text fields, select it using the globe key. Apple disables third-party keyboards in password fields and in apps that opt out.

The main app has a keyboard setup and test page accessible from Modules and Settings. Signing the embedded extension with a free Apple team / xtool needs real-device validation; do not assume a clean CI build guarantees installation.

## Build

The project uses **SwiftUI and XcodeGen**. The Xcode project is generated on demand:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project AllInOne.xcodeproj -scheme AllInOne -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

The GitHub Actions release pipeline creates an **unsigned IPA** for later local signing and installation, for example with [xtool](https://github.com/xtool-org/xtool) on your own computer. Do **not** upload your Apple ID, provisioning profiles, or private signing keys to GitHub.

## Automatic releases

After a successful `CI` build of a non-documentation commit on `main`, `Release` automatically builds a new **unsigned IPA** and publishes a prerelease. The first automated version uses `MARKETING_VERSION` from `project.yml` if it is ahead of the published releases; subsequent builds increment the patch (e.g. `v0.2.0`, `v0.2.1`). Superseded CI runs are skipped. Changes to README / Docs alone do not trigger CI or releases. Apple credentials remain only on your local machine and signed apps must still be installed through xtool.

## Releases — three manual triggers

The `Release` workflow supports:

1. **Git tag** `vX.Y.Z` pushed to GitHub: build and create a release if one does not exist.
2. **Actions → Release → Run workflow**: build and optionally publish a release.
3. **GitHub Releases → Publish release**: build and attach the IPA to the existing release.

Every build also uploads an Actions artifact. Release builds are unsigned and need local signing before installation. CI validates builds on pull requests and `main`.

## Requirements

- iOS 17 or newer
- A compatible macOS/Xcode toolchain for local compilation, or GitHub Actions
- Personal signing/installation tool for real-device testing

## Design

See [DESIGN.md](Docs/DESIGN.md) and [ROADMAP.md](Docs/ROADMAP.md). Visual language: dark-first, layered neutral surfaces, crisp typography, restrained distinct accent colors by module, no fabricated metrics or pretend operational states.

## License

MIT — see [LICENSE](LICENSE). Third-party components will retain their own notices and licenses when integrated.
