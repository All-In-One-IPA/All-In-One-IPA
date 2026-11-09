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
- [ ] Verify compile and install on an actual iPhone
- [ ] Test xtool installation, profile refresh and data persistence

## Next — practical utility modules

1. SSH terminal, SFTP browser and secure connection profiles
2. DNS mobileconfig creation/validation/export
3. Local media player and Files integration
4. Real activity log and background task status

## Later — advanced functionality

- Port **Flowseal/tg-ws-proxy**, respecting its MIT license and keeping its functionality distinct from optional remote Telemt relays.
- Prototype local MTProto / SOCKS5 endpoint and investigate iOS lifecycle and App Intents. Location-based background operation is an experiment, not a guaranteed daemon.
- Keyboard extension and free provisioning compatibility checks.
- Torrent engine with explicit foreground/background limitations; remote download management.
- IMAP/SMTP mail, Beszel dashboard, Docker/remote API clients, archives and Network Lab.
- Multiple languages, comprehensive accessibility and usability testing.

## Constraints

The public CI workflow builds *unsigned* IPAs. It must not handle Apple ID credentials or signing secrets. Local xtool can prepare profiles, sign and install the IPA. Free Apple provisioning and iOS sandbox restrictions still apply. No VPN tunnel or push entitlement is assumed.
