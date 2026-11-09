# Development roadmap

## v0.1.0 — interface foundation

- [x] SwiftUI app with native tabs and navigation
- [x] Dynamic dark / light / system appearance
- [x] Searchable and filterable 12-module catalogue
- [x] Home feature panel and upcoming tools
- [x] Individual module detail screens with honest statuses
- [x] Local-only saved device endpoint cards
- [x] GitHub Actions macOS CI and unsigned IPA release pipeline
- [x] Release triggers: version tag, manual dispatch, published release
- [x] Verify v0.1.0 compile and install on an iPhone 11 via xtool
- [ ] Verify weekly profile refresh and data persistence

## v0.2.0 — first real module

- [x] Add a real iOS Keyboard Extension target with RU/EN layout
- [x] Shift, Caps Lock, numbers, symbols, repeat backspace and keyboard switching
- [x] Local light/dark keyboard theme; no Full Access requirement
- [x] Setup guidance and a text input test screen in the main app
- [ ] Verify extension builds in GitHub Actions
- [ ] Verify free-team provisioning and launch on iPhone 11 via xtool
- [ ] Refine layout, landscape behavior and VoiceOver after device testing

## Next — practical utility modules

1. SSH terminal, SFTP browser and secure connection profiles
2. DNS mobileconfig creation/validation/export
3. Local media player and Files integration
4. Real activity log and background task status

## Later — advanced functionality

- Port **Flowseal/tg-ws-proxy**, respecting its MIT license and keeping its functionality distinct from optional remote Telemt relays.
- Prototype local MTProto / SOCKS5 endpoint and investigate iOS lifecycle and App Intents. Location-based background operation is an experiment, not a guaranteed daemon.
- Keyboard extension: add cursor control, customizable rows, text shortcuts, languages and optional dictionaries after initial testing.
- Torrent engine with explicit foreground/background limitations; remote download management.
- IMAP/SMTP mail, Beszel dashboard, Docker/remote API clients, archives and Network Lab.
- Multiple languages, comprehensive accessibility and usability testing.

## Constraints

The public CI workflow builds *unsigned* IPAs. It must not handle Apple ID credentials or signing secrets. Local xtool can prepare profiles, sign and install the IPA. Free Apple provisioning and iOS sandbox restrictions still apply. No VPN tunnel or push entitlement is assumed.

## Shared module foundation & CI/CD

- [x] Separate module definitions for tg-ws-proxy, SSH, DNS, Media, Torrent, Mail, Beszel, Network Lab, Archives, Server Tools and Automation
- [x] Typed configuration fields with validation and per-module local save/reset
- [x] Working manual HTTPS HEAD probe in Network Lab
- [x] Release workflow chained to successful CI on code changes in main
- [x] Automatic semantic patch increments, unsigned IPA distribution and SHA256 verification
- [ ] Implement each real module independently with secure credentials and tests
