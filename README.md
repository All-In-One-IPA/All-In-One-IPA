# All-In-One

A personal, modular iOS utility app built with SwiftUI. One place for network tools, remote access, media, downloads, and everyday utilities.

> **Status: interface preview.** Version 0.1.0 contains real navigation, a searchable module catalogue, appearance settings and module detail pages. Modules are **not** functional yet; their states are clearly marked.

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
| Custom keyboard extension | Research |
| Beszel dashboard | Planned |
| Network diagnostics | Planned |
| Archive manager | Planned |

The planned tg-ws-proxy integration specifically refers to **Flowseal/tg-ws-proxy**, a local Telegram MTProto proxy. It is **not** a Telemt relay. Background execution on iOS requires device testing and is not promised.

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
