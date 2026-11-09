# Interface design

## Direction

A pragmatic iPhone utility suite, not a generic admin panel. The visual vocabulary is deliberately quiet and precise: high-contrast typography, charcoal surfaces, asymmetric featured content and recognizable per-category color.

## Tokens

| Role | Dark | Light |
| --- | --- | --- |
| Background | `#0C1119` | `#F4F6F9` |
| Surface | `#171F2B` | `#FFFFFF` |
| Elevated | `#202B39` | `#EAF0F5` |
| Ink | `#F3F5F8` | `#192333` |
| Secondary ink | `#9FAEC1` | `#64748A` |
| Border | `#304050` | `#DFE5EB` |

Category colors: network / cyan; remote access / green; media / lavender; utilities / amber; system / coral.

## Design rules

1. Use native SF Symbols and system typography. No emoji or decorative stock photography.
2. Use prominent hierarchy only where it conveys a real state or an important action.
3. Larger feature panels should be visually different from catalog rows.
4. Avoid fake uptime, performance metrics, and sample running tasks. Everything not implemented is marked as planned.
5. Cards have rounded continuous corners, low-contrast borders and minimal shadow.
6. System and light appearance must remain usable; dynamic surfaces adapt without replacing category accents.
7. Make text legible with Dynamic Type improvements in subsequent iterations and verify VoiceOver semantics on device.

## Navigation

- Home: editorial overview; featured tg-ws-proxy.
- Modules: real text search and category filter.
- Activity: honest empty state until event storage exists.
- Devices: save/delete endpoint cards locally; no network requests in v0.1.
- Settings: actual appearance selection and source link.
- Module details: planned features, status, clear explanation.

## Future

When modules become functional, retain this identity and replace placeholder data with actual live state. Add keychain-backed secrets, proper activity persistence, accessibility tests, localizations and additional custom components where justified.
