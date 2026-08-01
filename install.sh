#!/usr/bin/env bash
# ==============================================================================
# QuickShell & Dracula Pro Ecosystem Installer
# Optimized for Nobara Linux (Fedora-based), Arch Linux, and Debian/Ubuntu
# ==============================================================================

set -eo pipefail

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

# 5. Copying and Linking Configurations
deploy_configs() {
    info "Deploying QuickShell configuration to ${TARGET_CONFIG_DIR}..."
    mkdir -p "${TARGET_CONFIG_DIR}"

    # Quickshell Desktop Shell Config (Symlinked to repo so git pull auto-updates ~/.config/quickshell)
    if [ -d "${SCRIPT_DIR}/quickshell" ]; then
        info "Linking QuickShell QML ecosystem..."
        rm -rf "${TARGET_CONFIG_DIR}/quickshell"
        ln -snf "${SCRIPT_DIR}/quickshell" "${TARGET_CONFIG_DIR}/quickshell" || cp -r "${SCRIPT_DIR}/quickshell" "${TARGET_CONFIG_DIR}/quickshell"
        chmod +x "${SCRIPT_DIR}/quickshell/toggle_launcher.sh"
        chmod +x "${SCRIPT_DIR}/quickshell/services/python/"*.py 2>/dev/null || true
    fi

    # Fastfetch Hampter Config (Symlinked to repo so git pull auto-updates ~/.config/fastfetch)
    if [ -d "${SCRIPT_DIR}/fastfetch" ]; then
        info "Linking Fastfetch Hampter configuration..."
        rm -rf "${TARGET_CONFIG_DIR}/fastfetch"
        ln -snf "${SCRIPT_DIR}/fastfetch" "${TARGET_CONFIG_DIR}/fastfetch" || cp -r "${SCRIPT_DIR}/fastfetch" "${TARGET_CONFIG_DIR}/fastfetch"
    fi

    success "QuickShell configuration linked successfully to ${TARGET_CONFIG_DIR}!"
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
    SERVICE_DIR="${TARGET_CONFIG_DIR}/systemd/user"
    mkdir -p "$SERVICE_DIR"

    cat << EOF > "${SERVICE_DIR}/quickshell.service"
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
EOF

    systemctl --user daemon-reload
    systemctl --user enable quickshell.service || warn "Could not enable quickshell service automatically"
    info "Starting QuickShell systemd service..."
    systemctl --user restart quickshell.service || warn "Could not start quickshell service automatically (is a Wayland session running?)"
    success "Systemd user service configured!"
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
        success "Multi-app themes dynamically generated across GTK, Alacritty, VSCode, Zen, Feishin, Starship, btop, fastfetch, ghostty, micro, konsole, and Xresources!"
    else
        warn "theme_sync.py not found at ${THEME_SYNC_SCRIPT}"
    fi
}

# Execution Flow
install_dependencies
install_quickshell
install_wallust_lutgen
deploy_configs
deploy_kde_colorschemes
setup_bashrc
setup_systemd_service
run_initial_sync

echo ""
echo -e "${GREEN}${BOLD}=========================================================="
echo "    QuickShell Ecosystem Successfully Installed!         "
echo "=========================================================="${NC}
echo -e "${CYAN}Key Commands & Shortcuts:${NC}"
echo " - App Launcher Toggle Script: ${TARGET_CONFIG_DIR}/quickshell/toggle_launcher.sh"
echo " - Systemd Service Management: systemctl --user [start|stop|restart|status] quickshell.service"
echo " - Manual Theme Sync: python3 ${TARGET_CONFIG_DIR}/quickshell/services/python/theme_sync.py"
echo ""
