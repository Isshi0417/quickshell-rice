#!/usr/bin/env bash
# ==============================================================================
# QuickShell & Dracula Pro Ecosystem Installer
# Optimized for Nobara Linux (Fedora-based), Arch Linux, and Debian/Ubuntu
# ==============================================================================

set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Formatting & Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${CYAN}${BOLD}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"; }
error() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_CONFIG_DIR="${HOME}/.config"

echo -e "${BOLD}${CYAN}"
echo "=========================================================="
echo "    QuickShell Desktop Shell & Theme Ecosystem Installer  "
echo "=========================================================="
echo -e "${NC}"

# 1. OS & Package Manager Detection
detect_pm() {
    if command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

PM=$(detect_pm)
info "Detected Package Manager: ${PM}"

# 2. Dependency Installation
install_dependencies() {
    info "Installing system dependencies..."
    case "$PM" in
        dnf)
            info "Running DNF installation for Nobara / Fedora..."
            sudo dnf install -y \
                python3 \
                python3-pillow \
                python3-dbus \
                pipewire \
                wireplumber \
                brightnessctl \
                ddcutil \
                NetworkManager \
                bluez \
                playerctl \
                wl-clipboard \
                cliphist \
                fastfetch \
                power-profiles-daemon \
                upower \
                curl \
                jq \
                libnotify \
                lm_sensors \
                lsblk \
                tar \
                gzip \
                awk \
                sed \
                grep \
                starship \
                alacritty \
                wmctrl \
                xdotool \
                papirus-icon-theme \
                qt6-qtdeclarative \
                qt6-qtdeclarative-devel \
                qt6-qtbase \
                qt6-qtbase-devel \
                layer-shell-qt \
                layer-shell-qt-devel \
                cmake \
                gcc-c++ || warn "Some packages failed to install via DNF, continuing..."
            ;;
        pacman)
            info "Running Pacman installation for Arch Linux / CachyOS..."
            sudo pacman -S --needed --noconfirm \
                python \
                python-pillow \
                python-dbus \
                pipewire \
                wireplumber \
                brightnessctl \
                ddcutil \
                networkmanager \
                bluez \
                bluez-utils \
                playerctl \
                wl-clipboard \
                cliphist \
                fastfetch \
                power-profiles-daemon \
                upower \
                curl \
                jq \
                libnotify \
                lm_sensors \
                lsblk \
                starship \
                alacritty \
                papirus-icon-theme \
                wmctrl \
                xdotool || warn "Some packages failed to install via Pacman, continuing..."
            ;;
        apt)
            info "Running APT installation for Debian / Ubuntu..."
            sudo apt-get update
            sudo apt-get install -y \
                python3 \
                python3-pil \
                python3-dbus \
                pipewire \
                wireplumber \
                brightnessctl \
                ddcutil \
                network-manager \
                bluez \
                playerctl \
                wl-clipboard \
                cliphist \
                fastfetch \
                power-profiles-daemon \
                upower \
                curl \
                jq \
                libnotify-bin \
                lm-sensors \
                starship \
                alacritty \
                papirus-icon-theme \
                wmctrl \
                xdotool || warn "Some packages failed to install via APT, continuing..."
            ;;
        *)
            warn "Unrecognized package manager. Please ensure Python3, Qt6, Wayland tools, and Pipewire are installed."
            ;;
    esac
}

# 3. Quickshell Binary Check / Build
install_quickshell() {
    if command -v quickshell &>/dev/null; then
        success "QuickShell binary found at $(which quickshell)"
        return 0
    fi

    info "QuickShell binary not found. Attempting installation..."

    if [ "$PM" = "dnf" ]; then
        info "Checking Fedora COPR repository for quickshell..."
        sudo dnf copr enable -y outfoxxed/quickshell 2>/dev/null || true
        if sudo dnf install -y quickshell 2>/dev/null; then
            success "QuickShell successfully installed via DNF COPR!"
            return 0
        fi
    elif [ "$PM" = "pacman" ]; then
        if command -v yay &>/dev/null; then
            yay -S --needed --noconfirm quickshell-git && return 0
        elif command -v paru &>/dev/null; then
            paru -S --needed --noconfirm quickshell-git && return 0
        fi
    fi

    warn "QuickShell package build required from git repository..."
    BUILD_DIR=$(mktemp -d)
    git clone https://git.outfoxxed.me/outfoxxed/quickshell.git "$BUILD_DIR"
    cmake -B "$BUILD_DIR/build" -S "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
    cmake --build "$BUILD_DIR/build"
    sudo cmake --install "$BUILD_DIR/build"
    rm -rf "$BUILD_DIR"
    success "QuickShell built and installed from source!"
}

# 4. Wallust & Lutgen Binary Check / Installation
install_wallust_lutgen() {
    info "Checking wallust and lutgen installation..."

    ensure_cargo() {
        if ! command -v cargo &>/dev/null && [ ! -f "$HOME/.cargo/bin/cargo" ]; then
            info "Installing Cargo package manager for Rust tools..."
            case "$PM" in
                dnf) sudo dnf install -y cargo rust || true ;;
                pacman) sudo pacman -S --needed --noconfirm rust cargo || true ;;
                apt) sudo apt-get install -y cargo rustc || true ;;
            esac
        fi
    }

    # Install wallust
    if command -v wallust &>/dev/null || [ -f "$HOME/.cargo/bin/wallust" ]; then
        success "wallust binary found!"
    else
        info "Installing wallust..."
        if [ "$PM" = "pacman" ] && command -v yay &>/dev/null; then
            yay -S --needed --noconfirm wallust || { ensure_cargo; cargo install wallust; } || warn "Could not install wallust"
        elif [ "$PM" = "pacman" ] && command -v paru &>/dev/null; then
            paru -S --needed --noconfirm wallust || { ensure_cargo; cargo install wallust; } || warn "Could not install wallust"
        else
            ensure_cargo
            cargo install wallust || warn "Could not install wallust"
        fi
    fi

    # Install lutgen
    if command -v lutgen &>/dev/null || [ -f "$HOME/.cargo/bin/lutgen" ] || command -v lutgen-cli &>/dev/null; then
        success "lutgen binary found!"
    else
        info "Installing lutgen..."
        if [ "$PM" = "pacman" ] && command -v yay &>/dev/null; then
            yay -S --needed --noconfirm lutgen-cli || { ensure_cargo; cargo install lutgen; } || warn "Could not install lutgen"
        elif [ "$PM" = "pacman" ] && command -v paru &>/dev/null; then
            paru -S --needed --noconfirm lutgen-cli || { ensure_cargo; cargo install lutgen; } || warn "Could not install lutgen"
        else
            ensure_cargo
            cargo install lutgen || warn "Could not install lutgen"
        fi
    fi
}

# 5. Papirus Folders Tool Installation
install_papirus_folders() {
    info "Checking papirus-folders installation..."
    if command -v papirus-folders &>/dev/null; then
        success "papirus-folders found at $(which papirus-folders)"
        return 0
    fi

    info "Installing papirus-folders for dynamic Papirus folder colorization..."
    if [ "$PM" = "pacman" ]; then
        if command -v yay &>/dev/null; then
            yay -S --needed --noconfirm papirus-folders-git 2>/dev/null && return 0
        elif command -v paru &>/dev/null; then
            paru -S --needed --noconfirm papirus-folders-git 2>/dev/null && return 0
        fi
    fi

    # Universal install fallback via official Papirus git repo
    info "Installing papirus-folders via official repository installer..."
    curl -sS https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh | sh 2>/dev/null || {
        BUILD_DIR=$(mktemp -d)
        git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$BUILD_DIR"
        sudo cp "$BUILD_DIR/papirus-folders" /usr/local/bin/papirus-folders 2>/dev/null || sudo cp "$BUILD_DIR/papirus-folders" /usr/bin/papirus-folders
        sudo chmod +x /usr/local/bin/papirus-folders 2>/dev/null || sudo chmod +x /usr/bin/papirus-folders
        rm -rf "$BUILD_DIR"
    }
    success "papirus-folders installed successfully!"
}

# Helper to safely unlink or remove existing config target before relinking
safe_unlink() {
    local target="$1"
    if [ -L "$target" ]; then
        info "Unlinking existing symbolic link at ${target}..."
        unlink "$target" 2>/dev/null || rm -f "$target"
    elif [ -d "$target" ]; then
        rm -rf "$target"
    fi
}

# 5. Copying and Linking Configurations
deploy_configs() {
    info "Deploying QuickShell configuration to ${TARGET_CONFIG_DIR}..."
    mkdir -p "${TARGET_CONFIG_DIR}"

    # Quickshell Desktop Shell Config (Symlinked to repo so git pull auto-updates ~/.config/quickshell)
    if [ -d "${SCRIPT_DIR}/quickshell" ]; then
        info "Unlinking existing & linking QuickShell QML ecosystem..."
        safe_unlink "${TARGET_CONFIG_DIR}/quickshell"
        ln -snf "${SCRIPT_DIR}/quickshell" "${TARGET_CONFIG_DIR}/quickshell" || cp -r "${SCRIPT_DIR}/quickshell" "${TARGET_CONFIG_DIR}/quickshell"
        chmod +x "${SCRIPT_DIR}/quickshell/toggle_launcher.sh"
        chmod +x "${SCRIPT_DIR}/quickshell/services/python/"*.py 2>/dev/null || true
    fi

    # Fastfetch Hampter Config (Symlinked to repo so git pull auto-updates ~/.config/fastfetch)
    if [ -d "${SCRIPT_DIR}/fastfetch" ]; then
        info "Unlinking existing & linking Fastfetch Hampter configuration..."
        safe_unlink "${TARGET_CONFIG_DIR}/fastfetch"
        ln -snf "${SCRIPT_DIR}/fastfetch" "${TARGET_CONFIG_DIR}/fastfetch" || cp -r "${SCRIPT_DIR}/fastfetch" "${TARGET_CONFIG_DIR}/fastfetch"
    fi

    # Alacritty Configuration (Symlinked to repo so quality of life updates apply automatically)
    if [ -d "${SCRIPT_DIR}/alacritty" ]; then
        info "Unlinking existing & linking Alacritty configuration..."
        safe_unlink "${TARGET_CONFIG_DIR}/alacritty"
        ln -snf "${SCRIPT_DIR}/alacritty" "${TARGET_CONFIG_DIR}/alacritty" || cp -r "${SCRIPT_DIR}/alacritty" "${TARGET_CONFIG_DIR}/alacritty"
    fi

    # Wallust Configuration (Symlinked to repo so template updates apply automatically)
    if [ -d "${SCRIPT_DIR}/wallust" ]; then
        info "Unlinking existing & linking Wallust configuration..."
        safe_unlink "${TARGET_CONFIG_DIR}/wallust"
        ln -snf "${SCRIPT_DIR}/wallust" "${TARGET_CONFIG_DIR}/wallust" || cp -r "${SCRIPT_DIR}/wallust" "${TARGET_CONFIG_DIR}/wallust"
    fi

    # Wallpapers Deployment & Lutgen Folder Setup
    deploy_wallpaper_folders

    success "QuickShell configuration linked successfully to ${TARGET_CONFIG_DIR}!"
}

# Helper to create all theme wallpaper directories for lutgen recolor engine
deploy_wallpaper_folders() {
    info "Setting up Lutgen theme wallpaper folders in ~/Pictures/Wallpapers..."
    WP_BASE="${HOME}/Pictures/Wallpapers"
    mkdir -p "$WP_BASE"

    local VARIANTS=(
        "Zoey Pink" "Zoey Night" "Emo Zoey"
        "Pro" "Blade" "Buff" "Cyan" "Lincoln" "Morpheus" "Alucard"
        "Everblush"
        "Gruvbox Dark" "Gruvbox Material" "Gruvbox Light"
        "Rosé Pine" "Rosé Pine Moon" "Rosé Pine Dawn"
        "Catppuccin Mocha" "Catppuccin Macchiato" "Catppuccin Latte"
        "Everforest Dark" "Everforest Light"
        "Tokyo Night" "Tokyo Night Storm" "Tokyo Night Day"
        "Nord Dark" "Nord Light"
        "Solarized Dark" "Solarized Light"
        "One Dark Pro" "One Light"
        "Monokai Pro" "Cyberpunk Neon" "Custom"
    )

    for v in "${VARIANTS[@]}"; do
        mkdir -p "${WP_BASE}/${v}"
    done

    if [ -d "${SCRIPT_DIR}/quickshell/wallpapers" ]; then
        info "Deploying wallpapers and recolored variants to ~/Pictures/Wallpapers..."
        cp -rn "${SCRIPT_DIR}/quickshell/wallpapers/"* "${WP_BASE}/" 2>/dev/null || true
    fi

    success "Lutgen wallpaper folders and images deployed to ${WP_BASE}!"
}

# 6. Deploy KDE Color Schemes & Konsole Profiles
deploy_kde_colorschemes() {
    info "Deploying KDE Plasma color schemes to ~/.local/share/color-schemes..."
    COLOR_SCHEMES_DIR="${HOME}/.local/share/color-schemes"
    KONSOLE_DIR="${HOME}/.local/share/konsole"

    mkdir -p "$COLOR_SCHEMES_DIR" "$KONSOLE_DIR"

    if [ -d "${SCRIPT_DIR}/kde/color-schemes" ]; then
        cp -r "${SCRIPT_DIR}/kde/color-schemes/"*.colors "$COLOR_SCHEMES_DIR/" 2>/dev/null || true
        chmod 644 "$COLOR_SCHEMES_DIR/"*.colors 2>/dev/null || true
        success "KDE color schemes deployed to ${COLOR_SCHEMES_DIR}"
    fi

    if [ -d "${SCRIPT_DIR}/kde/konsole" ]; then
        cp -r "${SCRIPT_DIR}/kde/konsole/"*.colorscheme "$KONSOLE_DIR/" 2>/dev/null || true
        chmod 644 "$KONSOLE_DIR/"*.colorscheme 2>/dev/null || true
        success "Konsole profiles deployed to ${KONSOLE_DIR}"
    fi

    # Execute dynamic KDE color scheme generator to ensure all 38 variants are updated
    KDE_GEN_SCRIPT="${TARGET_CONFIG_DIR}/quickshell/services/python/generate_kde_colorschemes.py"
    if [ -f "$KDE_GEN_SCRIPT" ]; then
        info "Running dynamic KDE color scheme generator..."
        python3 "$KDE_GEN_SCRIPT" || warn "KDE color scheme generator finished with warnings."
        success "Generated 38 KDE Plasma color schemes in ${COLOR_SCHEMES_DIR}"
    fi

    # Ensure KDE Plasma ScreenLocker autolock is enabled for QuickShell integration
    kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock true 2>/dev/null || true
    kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume true 2>/dev/null || true
    kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 5 2>/dev/null || true
}

# 7. Bashrc Fastfetch Setup
setup_bashrc() {
    info "Setting up fastfetch in ~/.bashrc..."
    BASHRC_FILE="${HOME}/.bashrc"
    if [ -f "$BASHRC_FILE" ]; then
        if ! grep -q "fastfetch" "$BASHRC_FILE"; then
            echo "" >> "$BASHRC_FILE"
            echo "# Run fastfetch on terminal startup" >> "$BASHRC_FILE"
            echo "fastfetch" >> "$BASHRC_FILE"
            success "Fastfetch added to ~/.bashrc"
        else
            info "Fastfetch already present in ~/.bashrc"
        fi
    fi
}

# 6. Systemd User Service Setup
setup_systemd_service() {
    info "Setting up Systemd User Service for QuickShell..."
    SERVICE_DIR="${HOME}/.config/systemd/user"
    mkdir -p "$SERVICE_DIR"

    # Dynamically detect quickshell binary on target machine or fallback to /usr/bin/env
    QUICKSHELL_BIN="$(command -v quickshell 2>/dev/null || echo '/usr/bin/env quickshell')"

    cat << EOF > "${SERVICE_DIR}/quickshell.service"
[Unit]
Description=QuickShell Desktop Shell Ecosystem
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=${QUICKSHELL_BIN} -p %h/.config/quickshell
Restart=always
RestartSec=3
Environment=QT_QPA_PLATFORM=wayland
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:%h/.local/bin:%h/.cargo/bin

[Install]
WantedBy=graphical-session.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable quickshell.service 2>/dev/null || warn "Could not enable quickshell service automatically"
    info "Starting QuickShell systemd service..."
    systemctl --user restart quickshell.service 2>/dev/null || warn "Could not start quickshell service automatically (is a Wayland session running?)"
    success "Systemd user service configured at ${SERVICE_DIR}/quickshell.service!"
}

# Helper to set Feishin theme to default and repair sandbox configurations
repair_feishin_flatpak() {
    info "Setting Feishin theme to default & repairing sandbox configurations..."
    python3 -c "
import os, json
home = os.path.expanduser('~')
target_dirs = [
    os.path.join(home, '.config', 'feishin'),
    os.path.join(home, '.local', 'share', 'feishin')
]

var_app = os.path.join(home, '.var', 'app')
if os.path.exists(var_app):
    for d in os.listdir(var_app):
        if 'feishin' in d.lower():
            for sub in ['config/feishin', 'data/feishin', 'config', 'data']:
                target_dirs.append(os.path.join(var_app, d, sub))

for td in target_dirs:
    if os.path.exists(td):
        # Clean up / sanitize invalid Electron theme strings and ensure comfortable window bounds
        for fn in ['config.json', 'preferences.json', 'settings.json']:
            fp = os.path.join(td, fn)
            if os.path.exists(fp):
                try:
                    with open(fp, 'r', encoding='utf-8') as f: data = json.load(f)
                    if isinstance(data, dict):
                        mod = False
                        if list(data.keys()) == ['theme'] and data['theme'] not in ['dark', 'light', 'system', 'defaultDark', 'defaultLight']:
                            os.remove(fp)
                            continue
                        elif 'theme' in data and data['theme'] not in ['dark', 'light', 'system', 'defaultDark', 'defaultLight']:
                            data['theme'] = 'dark'
                            mod = True
                        bounds = data.get('bounds', {})
                        if isinstance(bounds, dict) and (bounds.get('width', 0) < 1000 or bounds.get('height', 0) < 700):
                            data['bounds'] = {'x': bounds.get('x', 50), 'y': bounds.get('y', 50), 'width': 1280, 'height': 800}
                            mod = True
                        if mod:
                            with open(fp, 'w', encoding='utf-8') as f: json.dump(data, f, indent=2)
                except Exception: pass
" 2>/dev/null || true
}

# 7. Run Theme Sync Engine
run_initial_sync() {
    info "Triggering initial multi-app dynamic theme synchronization..."
    THEME_SYNC_SCRIPT="${TARGET_CONFIG_DIR}/quickshell/services/python/theme_sync.py"
    if [ -f "$THEME_SYNC_SCRIPT" ]; then
        python3 "$THEME_SYNC_SCRIPT" \
            --bg "#22212c" \
            --surface "#2b2938" \
            --currentLine "#454158" \
            --fg "#f8f8f2" \
            --accent "#9580ff" \
            --subAccent "#ff80bf" \
            --isDark true \
            --variantName Pro || warn "Theme sync script executed with warnings."
        success "Multi-app themes dynamically generated across GTK, Alacritty, VSCode, Zen, Feishin, Starship, btop, fastfetch, ghostty, micro, konsole, Papirus folders, and Xresources!"
    else
        warn "theme_sync.py not found at ${THEME_SYNC_SCRIPT}"
    fi
}

# Helper to setup refresh-quickshell script and bash alias
setup_refresh_script() {
    info "Installing refresh-quickshell binary script to ~/.local/bin/refresh-quickshell..."
    LOCAL_BIN="${HOME}/.local/bin"
    mkdir -p "$LOCAL_BIN"

    if [ -f "${SCRIPT_DIR}/refresh-quickshell" ]; then
        cp "${SCRIPT_DIR}/refresh-quickshell" "${LOCAL_BIN}/refresh-quickshell"
        chmod +x "${LOCAL_BIN}/refresh-quickshell"
        success "refresh-quickshell installed to ${LOCAL_BIN}/refresh-quickshell"
    fi

    BASHRC="${HOME}/.bashrc"
    if [ -f "$BASHRC" ]; then
        if ! grep -q "refresh-quickshell" "$BASHRC"; then
            echo "" >> "$BASHRC"
            echo "# QuickShell refresh-quickshell alias" >> "$BASHRC"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$BASHRC"
            echo "alias refresh-quickshell=\"\$HOME/.local/bin/refresh-quickshell\"" >> "$BASHRC"
            success "Added refresh-quickshell alias to ~/.bashrc"
        fi
    fi
}

setup_kwin_overview_rules() {
    info "Configuring KWin Overview rules to ignore QuickShell components..."
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kwinrulesrc --group "quickshell-ignore-overview" --key "Description" "Ignore QuickShell from KWin Overview Effect"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-ignore-overview" --key "wmclass" "quickshell"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-ignore-overview" --key "wmclassmatch" "1"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-ignore-overview" --key "skipoverview" "true"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-ignore-overview" --key "skipoverviewrule" "2"

        kwriteconfig6 --file kwinrulesrc --group "quickshell-lockscreen-ignore-overview" --key "Description" "Ignore QuickShell Lockscreen from KWin Overview Effect"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-lockscreen-ignore-overview" --key "wmclass" "lockscreen"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-lockscreen-ignore-overview" --key "wmclassmatch" "1"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-lockscreen-ignore-overview" --key "skipoverview" "true"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-lockscreen-ignore-overview" --key "skipoverviewrule" "2"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-lockscreen-ignore-overview" --key "skipswitcher" "true"
        kwriteconfig6 --file kwinrulesrc --group "quickshell-lockscreen-ignore-overview" --key "skipswitcherrule" "2"
        if command -v qdbus6 &>/dev/null; then
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
        fi
        success "KWin Overview exclusion rules configured for QuickShell & Lockscreen!"
    fi
}

# Execution Flow
install_dependencies
install_quickshell
install_wallust_lutgen
install_papirus_folders
deploy_configs
deploy_kde_colorschemes
repair_feishin_flatpak
setup_bashrc
setup_refresh_script
setup_kwin_overview_rules
setup_systemd_service
run_initial_sync

echo ""
echo -e "${GREEN}${BOLD}=========================================================="
echo "    QuickShell Ecosystem Successfully Installed!         "
echo "=========================================================="${NC}
echo -e "${CYAN}Key Commands & Shortcuts:${NC}"
echo " - Refresh Ecosystem Utility: refresh-quickshell (or ~/.local/bin/refresh-quickshell)"
echo " - App Launcher Toggle Script: ${TARGET_CONFIG_DIR}/quickshell/toggle_launcher.sh"
echo " - Systemd Service Management: systemctl --user [start|stop|restart|status] quickshell.service"
echo " - Manual Theme Sync: python3 ${TARGET_CONFIG_DIR}/quickshell/services/python/theme_sync.py"
echo ""
