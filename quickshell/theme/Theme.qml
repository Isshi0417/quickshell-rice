pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root

    property string currentVariant: "Pro"
    property string wallpaperPath: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers/Pro/lutgen_Pro_wallhaven.png"

    readonly property var themeCategories: [
        "All", "Zoey Pink", "Dracula Pro", "Gruvbox", "Rosé Pine", "Catppuccin", "Everforest", "Tokyo Night", "Nord", "Solarized", "One Theme", "Monokai", "Cyberpunk"
    ]

    readonly property var variants: [
        // Zoey Pink
        { category: "Zoey Pink",   name: "Zoey Pink",   isDark: false, accent: "#ec4899", subAccent: "#a855f7", bg: "#fff0f5", surface: "#fbcfe8", currentLine: "#f472b6", fg: "#4a044e" },
        { category: "Zoey Pink",   name: "Zoey Night",  isDark: true,  accent: "#f472b6", subAccent: "#c084fc", bg: "#251c2e", surface: "#33263e", currentLine: "#483659", fg: "#f5e6f8" },
        { category: "Zoey Pink",   name: "Emo Zoey",    isDark: true,  accent: "#ff2a85", subAccent: "#9333ea", bg: "#120914", surface: "#1c0d20", currentLine: "#32143a", fg: "#f4d7f7" },

        // Dracula Pro (Official Palette from dracula-pro/design/palette.md)
        { category: "Dracula Pro", name: "Pro",      isDark: true,  accent: "#9580ff", subAccent: "#ff80bf", bg: "#22212c", surface: "#2b2938", currentLine: "#454158", fg: "#f8f8f2", comment: "#7970a9" },
        { category: "Dracula Pro", name: "Blade",    isDark: true,  accent: "#80ffea", subAccent: "#8aff80", bg: "#212c2a", surface: "#293835", currentLine: "#415854", fg: "#f8f8f2", comment: "#70a99f" },
        { category: "Dracula Pro", name: "Buff",     isDark: true,  accent: "#ff80bf", subAccent: "#ff9580", bg: "#2a212c", surface: "#352938", currentLine: "#544158", fg: "#f8f8f2", comment: "#9f70a9" },
        { category: "Dracula Pro", name: "Cyan",     isDark: true,  accent: "#80ffea", subAccent: "#9580ff", bg: "#0b0d0f", surface: "#181b1f", currentLine: "#414d58", fg: "#f8f8f2", comment: "#708ca9" },
        { category: "Dracula Pro", name: "Lincoln",  isDark: true,  accent: "#ffff80", subAccent: "#8aff80", bg: "#2c2a21", surface: "#38352a", currentLine: "#585441", fg: "#f8f8f2", comment: "#a99f70" },
        { category: "Dracula Pro", name: "Morpheus", isDark: true,  accent: "#ff9580", subAccent: "#ffca80", bg: "#2c2122", surface: "#382a2b", currentLine: "#584145", fg: "#f8f8f2", comment: "#a97079" },
        { category: "Dracula Pro", name: "Alucard",  isDark: false, accent: "#644ac9", subAccent: "#a3144d", bg: "#f5f5f5", surface: "#cfcfde", currentLine: "#cfcfde", fg: "#1f1f1f", comment: "#635d97" },

        // Gruvbox
        { category: "Gruvbox",     name: "Gruvbox Dark",     isDark: true,  accent: "#fe8019", subAccent: "#fabd2f", bg: "#282828", surface: "#3c3836", currentLine: "#504945", fg: "#ebdbb2" },
        { category: "Gruvbox",     name: "Gruvbox Material", isDark: true,  accent: "#ea698c", subAccent: "#a9b665", bg: "#1d2021", surface: "#282828", currentLine: "#3c3836", fg: "#ddc7a1" },
        { category: "Gruvbox",     name: "Gruvbox Light",    isDark: false, accent: "#af3a03", subAccent: "#b57614", bg: "#fbf1c7", surface: "#ebdbb2", currentLine: "#d5c4a1", fg: "#3c3836" },

        // Rosé Pine
        { category: "Rosé Pine",   name: "Rosé Pine",        isDark: true,  accent: "#ebbcba", subAccent: "#c4a7e7", bg: "#191724", surface: "#1f1d2e", currentLine: "#26233a", fg: "#e0def4" },
        { category: "Rosé Pine",   name: "Rosé Pine Moon",   isDark: true,  accent: "#ea9a97", subAccent: "#c4a7e7", bg: "#232136", surface: "#2a273f", currentLine: "#393552", fg: "#e0def4" },
        { category: "Rosé Pine",   name: "Rosé Pine Dawn",   isDark: false, accent: "#d7827e", subAccent: "#907aa9", bg: "#faf4ed", surface: "#f2e9e1", currentLine: "#e4d7d0", fg: "#575279" },

        // Catppuccin
        { category: "Catppuccin",  name: "Catppuccin Mocha",    isDark: true,  accent: "#cba6f7", subAccent: "#89b4fa", bg: "#1e1e2e", surface: "#313244", currentLine: "#45475a", fg: "#cdd6f4" },
        { category: "Catppuccin",  name: "Catppuccin Macchiato",isDark: true,  accent: "#f5bde6", subAccent: "#8aadf4", bg: "#24273a", surface: "#363a4f", currentLine: "#494d64", fg: "#cad3f5" },
        { category: "Catppuccin",  name: "Catppuccin Latte",    isDark: false, accent: "#8839ef", subAccent: "#1e66f5", bg: "#eff1f5", surface: "#e6e9ef", currentLine: "#ccd0da", fg: "#4c4f69" },

        // Everforest
        { category: "Everforest",  name: "Everforest Dark",  isDark: true,  accent: "#a7c080", subAccent: "#7fbbb3", bg: "#2d353b", surface: "#343f44", currentLine: "#3d484d", fg: "#d3c6aa" },
        { category: "Everforest",  name: "Everforest Light", isDark: false, accent: "#8da101", subAccent: "#35a77c", bg: "#fdf6e3", surface: "#f4e0c5", currentLine: "#e5d5c5", fg: "#5c6a72" },

        // Tokyo Night
        { category: "Tokyo Night", name: "Tokyo Night",      isDark: true,  accent: "#7aa2f7", subAccent: "#bb9af7", bg: "#1a1b26", surface: "#24283b", currentLine: "#414868", fg: "#c0caf5" },
        { category: "Tokyo Night", name: "Tokyo Night Storm",isDark: true,  accent: "#7aa2f7", subAccent: "#7dcfff", bg: "#24283b", surface: "#1f2335", currentLine: "#414868", fg: "#c0caf5" },
        { category: "Tokyo Night", name: "Tokyo Night Day",  isDark: false, accent: "#2e7de9", subAccent: "#9854f6", bg: "#e1e2e7", surface: "#d5d6db", currentLine: "#c4c8da", fg: "#3760bf" },

        // Nord
        { category: "Nord",        name: "Nord Dark",        isDark: true,  accent: "#88c0d0", subAccent: "#b48ead", bg: "#2e3440", surface: "#3b4252", currentLine: "#434c5e", fg: "#eceff4" },
        { category: "Nord",        name: "Nord Light",       isDark: false, accent: "#5e81ac", subAccent: "#88c0d0", bg: "#eceff4", surface: "#e5e9f0", currentLine: "#d8dee9", fg: "#2e3440" },

        // Solarized
        { category: "Solarized",   name: "Solarized Dark",   isDark: true,  accent: "#268bd2", subAccent: "#2aa198", bg: "#002b36", surface: "#073642", currentLine: "#586e75", fg: "#839496" },
        { category: "Solarized",   name: "Solarized Light",  isDark: false, accent: "#268bd2", subAccent: "#d33682", bg: "#fdf6e3", surface: "#eee8d5", currentLine: "#93a1a1", fg: "#657b83" },

        // One Theme
        { category: "One Theme",   name: "One Dark Pro",     isDark: true,  accent: "#61afef", subAccent: "#c678dd", bg: "#282c34", surface: "#21252b", currentLine: "#3e4451", fg: "#abb2bf" },
        { category: "One Theme",   name: "One Light",        isDark: false, accent: "#4078f2", subAccent: "#a626a4", bg: "#fafafa", surface: "#f0f0f0", currentLine: "#e5e5e6", fg: "#383a42" },

        // Monokai
        { category: "Monokai",     name: "Monokai Pro",      isDark: true,  accent: "#ffd866", subAccent: "#ff6188", bg: "#2d2a2e", surface: "#3a3a3a", currentLine: "#4a4a4a", fg: "#fcfcfa" },

        // Cyberpunk
        { category: "Cyberpunk",   name: "Cyberpunk Neon",   isDark: true,  accent: "#ff007f", subAccent: "#00f0ff", bg: "#120e24", surface: "#22194d", currentLine: "#3a2a80", fg: "#00ff9f" }
    ]

    // Active Palette
    property bool isDark: true
    property string iconTheme: isDark ? "Papirus-Dark" : "Papirus-Light"
    property string panelIconDir: isDark ? "Papirus" : "Papirus-Light"

    property color bg: "#22212c"
    property color surface: "#2b2938"
    property color currentLine: "#454158"
    property color selection: "#454158"
    property color fg: "#f8f8f2"
    property color comment: "#7970a9"

    readonly property color separator: isDark ? currentLine : Qt.rgba(fg.r, fg.g, fg.b, 0.25)

    property color accent: "#9580ff"
    property color subAccent: "#ff80bf"

    property color cyan: "#80ffea"
    property color green: "#8aff80"
    property color orange: "#ffca80"
    property color pink: "#ff80bf"
    property color purple: "#9580ff"
    property color red: "#ff9580"
    property color yellow: "#ffff80"

    property color glassBg: bg
    property color glassBorder: currentLine
    property color glassHover: currentLine
    property int blurRadius: 0
    property int cornerRadius: 10

    function setVariant(name, isStartupRestoration) {
        for (let i = 0; i < variants.length; i++) {
            let v = variants[i]
            if (v.name === name) {
                currentVariant = v.name
                isDark = v.isDark !== undefined ? v.isDark : true
                iconTheme = isDark ? "Papirus-Dark" : "Papirus-Light"

                purple = v.accent
                accent = v.accent
                subAccent = v.subAccent ? v.subAccent : v.accent
                bg = v.bg
                surface = v.surface
                glassBg = v.bg
                currentLine = v.currentLine
                selection = v.currentLine
                glassBorder = v.currentLine
                glassHover = v.currentLine
                if (v.fg) fg = v.fg
                else fg = isDark ? "#f8f8f2" : "#282a36"

                if (v.comment) {
                    comment = v.comment
                } else {
                    comment = isDark ? "#7970a9" : Qt.rgba(fg.r, fg.g, fg.b, 0.65)
                }

                if (v.name === "Alucard") {
                    cyan = "#036a96"
                    green = "#14710a"
                    orange = "#a34d14"
                    pink = "#a3144d"
                    purple = "#644ac9"
                    red = "#cb3a2a"
                    yellow = "#846e15"
                } else if (isDark) {
                    cyan = "#80ffea"
                    green = "#8aff80"
                    orange = "#ffca80"
                    pink = "#ff80bf"
                    purple = "#9580ff"
                    red = "#ff9580"
                    yellow = "#ffff80"
                } else {
                    cyan = "#0891b2"
                    green = "#16a34a"
                    orange = "#ea580c"
                    pink = "#db2777"
                    red = "#dc2626"
                    yellow = "#d97706"
                }

                // Update system GTK & KDE icon theme and color scheme preference
                Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", iconTheme])
                Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", isDark ? "prefer-dark" : "prefer-light"])
                Quickshell.execDetached(["kwriteconfig6", "--group", "Icons", "--key", "Theme", iconTheme])
                
                Quickshell.execDetached([
                    "python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/theme_sync.py",
                    "--bg", v.bg,
                    "--surface", v.surface,
                    "--currentLine", v.currentLine,
                    "--fg", v.fg ? v.fg : "#f8f8f2",
                    "--accent", v.accent,
                    "--subAccent", v.subAccent,
                    "--isDark", isDark ? "true" : "false",
                    "--variantName", v.name
                ])
                
                AppLauncherService.reload()

                if (!isStartupRestoration) {
                    let imgPath = getVariantWallpaper(v.name)
                    if (WallpaperService) {
                        WallpaperService.applyWallpaper(imgPath, v.name)
                    } else {
                        wallpaperPath = imgPath.startsWith("file://") ? imgPath : "file://" + imgPath
                        let rawPath = imgPath.replace("file://", "")
                        Quickshell.execDetached(["plasma-apply-wallpaperimage", rawPath])
                    }
                    let rawPath = imgPath.replace("file://", "")
                    Quickshell.execDetached(["sh", "-c", "wallust run '" + rawPath + "' || ~/.cargo/bin/wallust run '" + rawPath + "' 2>/dev/null || true"])
                }

                // Persist selected theme variant to disk
                Quickshell.execDetached(["sh", "-c", "echo '" + v.name + "' > ~/.config/quickshell_current_theme.txt"])
                break
            }
        }
    }

    // Read saved theme variant on startup
    Process {
        id: readThemeProc
        command: ["bash", "-c", "cat ~/.config/quickshell_current_theme.txt 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let saved = data.trim()
                if (saved && saved !== "" && saved !== root.currentVariant) {
                    root.setVariant(saved, true)
                }
            }
        }
    }

    function getVariantWallpaper(varName) {
        if (!varName || varName === "") return ""
        let cur = varName.toLowerCase().trim()

        // 1. Check if user set/cached a custom wallpaper for this specific theme variant
        if (WallpaperService && WallpaperService.cachedThemeWallpapers && WallpaperService.cachedThemeWallpapers[varName]) {
            let cached = WallpaperService.cachedThemeWallpapers[varName]
            if (cached && cached !== "") return cached
        }

        // 2. Check scanned wallpapers folder for matching variant folder
        if (WallpaperService && WallpaperService.wallpapers) {
            for (let i = 0; i < WallpaperService.wallpapers.length; i++) {
                let wp = WallpaperService.wallpapers[i]
                if ((wp.variant || "").toLowerCase().trim() === cur) {
                    return wp.path
                }
            }
        }
        return Quickshell.env("HOME") + "/Pictures/Wallpapers/" + varName + "/wallhaven-yqg6r7_1920x1080.png"
    }

    function cycleVariant() {
        let idx = 0
        for (let i = 0; i < variants.length; i++) {
            if (variants[i].name === currentVariant) {
                idx = (i + 1) % variants.length
                break
            }
        }
        setVariant(variants[idx].name)
    }
}
