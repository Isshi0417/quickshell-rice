# Project: QuickShell KDE Widget Suite

## Architecture
Production-grade modular QuickShell UI framework integrating with KDE Plasma DBus services, custom Dracula Pro dynamic theme engine, glassmorphic styling, top status bar, bottom floating dock, and interactive overlay panels (Quick Settings, App Launcher, MPRIS, OSDs, Notification Center).

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Master Spec | Document DBus endpoints, QuickShell QML architecture, theme schemas, component specs in `QUICKSHELL_KDE_MASTER_SPEC.md` | none | DONE |
| 2 | Theme Engine & Glassmorphism | `ThemeManager.qml`, Dracula Pro palette engine (Blade, Buffy, Chrome, Lincoln, Morbius, Van Helsing), blur/glass styling, dynamic switching | M1 | DONE |
| 3 | Bars & Docks | Top Status Bar (workspaces, task title, metrics, clock, tray) & Bottom Dock (task tracking, launchers, animations) | M2 | IN_PROGRESS |
| 4 | Backend Services & Overlays | Quick Settings, App Launcher, MPRIS Controller, Notification Center & OSDs with 1:1 KDE DBus bindings | M2, M3 | PLANNED |
| 5 | E2E Testing & Hardening | Opaque-box E2E test runner, unit tests, QML syntax verification (`quickshell --check` / `qmlfmt`), adversarial hardening | M1-M4 | PLANNED |

## Interface Contracts
### Theme Engine ↔ UI Components
- `ThemeManager`: Singleton exposing `currentTheme`, `palette` (colors: background, surface, foreground, selection, accents: red, orange, yellow, green, cyan, purple, pink), `glass` properties (blurRadius, opacity, borderOpacity, shadow), and `setTheme(themeName)`.

### Services ↔ System DBus Wrappers
- `NetworkService`: DBus `org.freedesktop.NetworkManager` wrapper for Wi-Fi SSID listing, connection toggling, Ethernet status.
- `AudioService`: `WirePlumber` / PipeWire DBus wrapper for volume control, sink/source switching, mute status.
- `MprisService`: `org.mpris.MediaPlayer2` wrapper for player discovery, metadata, playback state, position, track controls.
- `NotificationService`: `org.freedesktop.Notifications` server implementation or DBus listener with history, notification categorization, OSD signals.
- `PowerService`: Battery status, power profiles (`power-profiles-daemon` or KDE PowerManagement), session management (Lock, Suspend, Reboot, Shutdown).
- `WorkspaceService`: KWin DBus wrapper (`org.kde.KWin`) for virtual desktop listing, switching, active window title/class tracking.

## Code Layout
- `QUICKSHELL_KDE_MASTER_SPEC.md`: Master Architecture & DBus Reference
- `shell.qml`: Main QuickShell entry point
- `theme/`: Theme Engine (`ThemeManager.qml`, `DraculaPro.qml`, palette definitions)
- `services/`: Backend DBus wrappers and singletons (`NetworkService.qml`, `AudioService.qml`, `MprisService.qml`, `NotificationService.qml`, `WorkspaceService.qml`, `PowerService.qml`, `BrightnessService.qml`)
- `components/`: UI building blocks (`GlassPanel.qml`, `IconButton.qml`, `Slider.qml`, `MeterBar.qml`, `Badge.qml`)
- `bar/`: Top Status Bar (`TopBar.qml`, `WorkspaceSwitcher.qml`, `WindowTitle.qml`, `SystemMetrics.qml`, `ClockWidget.qml`, `TrayWidget.qml`, `MprisSnippet.qml`)
- `dock/`: Bottom Floating Dock (`BottomDock.qml`, `DockItem.qml`, `WindowTracker.qml`)
- `overlays/`: Interactive Overlay Windows & Popups (`QuickSettingsPopup.qml`, `AppLauncher.qml`, `MprisPlayer.qml`, `NotificationCenter.qml`, `VolumeOSD.qml`, `BrightnessOSD.qml`)
- `tests/`: Automated test suite, test runner script, unit tests, E2E test harness
