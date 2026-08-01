# QuickShell Ecosystem: Zoey's Deployment & Setup Guide

Welcome to the **QuickShell Desktop Shell & Riced Theme Ecosystem**! This guide details how to install and run the complete self-contained desktop experience on **Zoey's computer (Nobara Linux / Fedora / Arch / Ubuntu)** directly out of her `~/.config` directory.

---

## 🌟 Architecture Overview

QuickShell is deployed as a 100% self-contained configuration located inside `~/.config/quickshell`:

- **Execution Directory**: `~/.config/quickshell/`
- **Systemd User Daemon**: `~/.config/systemd/user/quickshell.service` (executes `quickshell -p %h/.config/quickshell`)
- **Top Status Bar**: Dynamic workspace switcher, window title tracker, CPU/RAM/Temp metrics, digital clock with calendar dropdown, system tray, audio volume, brightness, battery, and MPRIS music player controls.
- **Bottom Dock**: Floating application launcher, pinned apps, window task bar, mouse-over micro-animations, and wallpaper selector.
- **Dynamic Multi-App Theme Engine (`~/.config/quickshell/services/python/theme_sync.py`)**:
  - Automatically generates and applies live color themes for **GTK 3/4**, **Alacritty**, **Discord**, **VSCode / VSCodium**, **Zen Browser**, **Feishin Music Player**, **Starship Prompt**, **btop**, **fastfetch**, **ghostty**, **micro editor**, **Konsole**, and **Xresources**.
  - Includes 30+ dark & light color palettes (Dracula Pro: Blade, Buff, Lincoln, Morpheus, Alucard; Catppuccin; Tokyo Night; Rosé Pine; Gruvbox; Everforest; Nord; Solarized; One Dark; Cyberpunk Neon).

---

## 🚀 Quick Automated Installation (Recommended)

On Zoey's computer running **Nobara Linux**, open a terminal in this repository directory and run:

```bash
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect Nobara (`dnf`) and install all required system packages.
2. Deploy QuickShell directly to `~/.config/quickshell/`.
3. Configure and enable `~/.config/systemd/user/quickshell.service`.
4. Trigger the initial dynamic theme sync across all supported apps.

---

## 🛠️ Step-by-Step Manual Setup for Nobara Linux

If installing manually:

### Step 1: Install Package Dependencies on Nobara (DNF)

Run the following command to install Python 3 libraries, PipeWire audio tools, DBus wrappers, and desktop utilities:

```bash
sudo dnf install -y \
    python3 python3-pillow python3-dbus \
    pipewire wireplumber brightnessctl ddcutil \
    NetworkManager bluez playerctl wl-clipboard cliphist \
    fastfetch power-profiles-daemon upower curl jq libnotify \
    lm_sensors lsblk starship alacritty wmctrl xdotool \
    qt6-qtdeclarative qt6-qtdeclarative-devel qt6-qtbase qt6-qtbase-devel \
    layer-shell-qt layer-shell-qt-devel cmake gcc-c++
```

### Step 2: Install QuickShell Engine

Check if `quickshell` is available via Fedora COPR:

```bash
sudo dnf copr enable -y outfoxxed/quickshell
sudo dnf install -y quickshell
```

*Fallback Build from Source (if package not found in COPR):*

```bash
git clone https://git.outfoxxed.me/outfoxxed/quickshell.git /tmp/quickshell-build
cd /tmp/quickshell-build
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

### Step 3: Deploy QuickShell Configuration to `~/.config/quickshell/`

Copy the QuickShell ecosystem into Zoey's `.config` directory:

```bash
mkdir -p ~/.config/quickshell
cp -r quickshell/* ~/.config/quickshell/
chmod +x ~/.config/quickshell/toggle_launcher.sh
chmod +x ~/.config/quickshell/services/python/*.py
```

### Step 4: Configure Systemd User Service

Create `~/.config/systemd/user/quickshell.service`:

```ini
[Unit]
Description=QuickShell Desktop Shell Ecosystem
After=graphical-session.target
PartOf=graphical-session.target

[Service]
ExecStart=/usr/bin/quickshell -p %h/.config/quickshell
Restart=always
RestartSec=2
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=graphical-session.target
```

Enable and start the service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now quickshell.service
```

### Step 5: Initialize Dynamic Multi-App Theme Engine

Run the theme sync engine directly out of `~/.config/quickshell/services/python/theme_sync.py`:

```bash
python3 ~/.config/quickshell/services/python/theme_sync.py \
    --bg "#22212c" --surface "#2b2938" --currentLine "#454158" \
    --fg "#f8f8f2" --accent "#9580ff" --subAccent "#ff80bf" \
    --isDark true --variantName Pro
```

---

## ⌨️ Binding the App Launcher Shortcut on Nobara / KDE

To bind the QuickShell App Launcher to the `Super` (Windows) key or a keyboard shortcut in Nobara / KDE Plasma:

1. Open **System Settings** -> **Keyboard** -> **Shortcuts**.
2. Click **Add New** -> **Command**.
3. Name: `Toggle QuickShell App Launcher`
4. Command: `~/.config/quickshell/toggle_launcher.sh`
5. Shortcut: Press `Super` or `Meta+Space` (or your preferred shortcut).
6. Click **Apply**.

---

## 🔍 Service & Process Management Commands

- **Check Shell Status**: `systemctl --user status quickshell.service`
- **Restart Desktop Shell**: `systemctl --user restart quickshell.service`
- **View Runtime Logs**: `journalctl --user -u quickshell.service -f`
- **Manual Theme Switch**: `python3 ~/.config/quickshell/services/python/theme_sync.py --bg "#1e1e2e" --surface "#313244" --currentLine "#45475a" --fg "#cdd6f4" --accent "#cba6f7" --subAccent "#89b4fa" --isDark true --variantName "Catppuccin Mocha"`

---

## 🎨 Adding Custom Wallpapers & Pinned Apps

- **Wallpapers**: Drop any `.png` or `.jpg` image into `~/.config/quickshell/wallpapers/`. QuickShell automatically indexes and displays them in the wallpaper switcher panel.
- **Pinned Apps**: Edit `~/.config/quickshell/config/pinned_apps.json` to customize default dock application icons and `.desktop` launchers.
