# Project: QuickShell & Backend Optimization Project

## Architecture
- **UI Layer**: `quickshell/` - QML components, panels, popups, and widgets running via QuickShell engine on Wayland.
- **Service Layer**: `quickshell/services/` - QML Service wrappers interfacing with system daemons/DBus/CLI tools.
- **Backend Layer**: `scripts/` - Shell and Python utilities providing system data (audio, brightness, network, mpris, weather, power, theme, wm, disks, clipboard).
- **Environment**: KDE Plasma on Wayland.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Pre-Flight Dependency Audit & Infra Setup (R4) | Audit missing tools, Python modules, CLI utilities, generate DEPENDENCIES.md | none | DONE |
| 2 | QuickShell QML Performance & Fluidity Optimization (R1) | Eliminate QML micro-stutters, binding bottlenecks, inefficient timers, optimize 60fps animations | M1 | DONE |
| 3 | Backend Script Optimization & Event-Driven Architecture (R2) | Refactor high-frequency shell polling in scripts/ & quickshell/services/ to event-driven/async non-blocking | M1 | DONE |
| 4 | KDE/Wayland Compatibility & Integration Verification (R3) | Verify WirePlumber, brightnessctl, nmcli, playerctl, KWin integration & fallback handling | M2, M3 | DONE |

## Interface Contracts
### QuickShell ↔ Backend Scripts / System Services
- Asynchronous non-blocking subprocess invocation (`Process` / `ProcessManager`).
- DBus signal listeners (`dbus-monitor`, `playerctl --follow`, `pactl subscribe`, `nmcli monitor`) feeding QuickShell signals without polling loop.
- Fallback signals/defaults when CLI tools or services are unavailable.

## Code Layout
- `quickshell/`: QML files, components, services, theme, bar/panel configurations
- `scripts/`: Shell scripts, Python scripts, daemon helpers
