# All-In-One

A personal, modular iOS utility app built with SwiftUI. One place for network tools, remote access, media, downloads, and everyday utilities.

> **Status: early development.** Version 0.2.0 adds a real offline iOS keyboard extension (RU/EN) to the existing interface. Other tools remain planned and are explicitly marked.

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

## Releases — three triggers

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
