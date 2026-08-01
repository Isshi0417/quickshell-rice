pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    // Pinned Application Defaults (Loaded dynamically from disk on startup)
    property var pinnedApps: [
        { appId: "alacritty", name: "Alacritty", icon: "Alacritty", cmd: "alacritty" },
        { appId: "dolphin", name: "Dolphin", icon: "org.kde.dolphin", cmd: "dolphin" },
        { appId: "firefox", name: "Firefox", icon: "firefox", cmd: "firefox" },
        { appId: "code", name: "VS Code", icon: "com.visualstudio.code", cmd: "code" },
        { appId: "kate", name: "Kate", icon: "kate", cmd: "kate" }
    ]

    property var runningWindows: []
    property var openWindowApps: []
    property bool isFullscreen: false
    property string activeAppId: ""
    property string activeWindowTitle: ""

    // Dynamic Unified Dock Model (Pinned Apps + Unpinned REAL Desktop Open Windows ONLY)
    readonly property var allDockApps: {
        let list = []

        // 1. Pinned Apps (Always present)
        for (let i = 0; i < pinnedApps.length; i++) {
            let p = pinnedApps[i]
            list.push({
                appId: p.appId,
                name: p.name || p.appId,
                icon: p.icon || p.appId,
                cmd: p.cmd || p.appId,
                isPinned: true
            })
        }

        // 2. Unpinned Apps (ONLY if they have a real open desktop window reported by KWin!)
        let addedAppIds = []
        for (let i = 0; i < pinnedApps.length; i++) {
            addedAppIds.push(pinnedApps[i].appId.toLowerCase())
        }

        for (let w = 0; w < openWindowApps.length; w++) {
            let winObj = openWindowApps[w]
            if (!winObj) continue;
            let winApp = typeof winObj === "string" ? winObj.toLowerCase().trim() : (winObj.appId || "").toLowerCase().trim()
            if (!winApp || winApp === "") continue;

            let isAlreadyAdded = false
            for (let k = 0; k < addedAppIds.length; k++) {
                let pinId = addedAppIds[k]
                if (winApp === pinId || winApp.includes(pinId) || pinId.includes(winApp)) {
                    isAlreadyAdded = true
                    break
                }
            }

            if (!isAlreadyAdded) {
                addedAppIds.push(winApp)
                let name = typeof winObj === "object" ? (winObj.name || winApp) : winApp
                let icon = typeof winObj === "object" ? (winObj.icon || winApp) : winApp

                list.push({
                    appId: winApp,
                    name: name,
                    icon: icon,
                    cmd: winApp,
                    isPinned: false
                })
            }
        }

        return list
    }

    function isPinned(appId) {
        if (!appId) return false;
        let lower = appId.toLowerCase()
        for (let i = 0; i < pinnedApps.length; i++) {
            if (pinnedApps[i].appId.toLowerCase() === lower || lower.includes(pinnedApps[i].appId.toLowerCase())) {
                return true
            }
        }
        return false
    }

    function isRunning(appId) {
        if (!appId) return false;
        let lower = appId.toLowerCase().trim()

        for (let i = 0; i < openWindowApps.length; i++) {
            let winObj = openWindowApps[i]
            let winApp = typeof winObj === "string" ? winObj.toLowerCase().trim() : (winObj.appId || "").toLowerCase().trim()
            if (winApp === lower || winApp.includes(lower) || lower.includes(winApp)) {
                return true
            }
        }
        return false
    }

    function isActive(appId) {
        if (!appId) return false;
        let lower = appId.toLowerCase().trim()

        if (!isRunning(lower)) return false;

        if (activeAppId && activeAppId !== "") {
            let actLower = activeAppId.toLowerCase().trim()
            if (actLower === lower || actLower.includes(lower) || lower.includes(actLower)) {
                return true
            }
        }
        return false
    }

    function focusApp(appId, cmd, iconX, iconY) {
        if (!appId) return;
        let lower = appId.toLowerCase().trim()
        let ix = Math.round(iconX || 0)
        let iy = Math.round(iconY || 0)

        if (isRunning(appId)) {
            let currentlyActive = isActive(appId)
            if (currentlyActive) {
                root.activeAppId = ""
            } else {
                root.activeAppId = lower
            }

            proc.running = false
            proc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/kwin_focus.py", lower, ix.toString(), iy.toString()]
            proc.running = true
        } else if (cmd || appId) {
            launchApp(cmd || appId)
        }
    }

    property real lastLaunchTime: 0
    property string lastLaunchCmd: ""

    function launchApp(cmd) {
        if (!cmd) return;
        let cleanCmd = cmd.trim()
        if (cleanCmd === "") return;

        let now = Date.now()
        if (cleanCmd === lastLaunchCmd && (now - lastLaunchTime) < 600) {
            return; // Ignore rapid double-clicks within 600ms
        }
        lastLaunchTime = now
        lastLaunchCmd = cleanCmd

        let execCmd = cleanCmd.replace(/%[a-zA-Z]/g, "").trim()
        root.activeAppId = execCmd.toLowerCase()

        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/launch_app.py", cleanCmd])
    }

    function closeApp(appId) {
        if (appId) {
            let lower = appId.toLowerCase().trim()
            if (isActive(appId)) root.activeAppId = ""
            proc.running = false
            proc.command = ["bash", "-c", "pkill -i -f " + appId + " 2>/dev/null &"]
            proc.running = true
        }
    }

    function toggleLauncher() {
        PopupService.toggleAppLauncher()
    }

    function togglePin(app) {
        if (!app || !app.appId) return;
        let existsIndex = -1
        let lower = app.appId.toLowerCase()
        for (let i = 0; i < pinnedApps.length; i++) {
            if (pinnedApps[i].appId.toLowerCase() === lower || lower.includes(pinnedApps[i].appId.toLowerCase())) {
                existsIndex = i
                break
            }
        }
        let list = Array.from(pinnedApps)
        if (existsIndex >= 0) {
            list.splice(existsIndex, 1)
        } else {
            list.push({
                appId: app.appId,
                name: app.name || app.appId,
                icon: app.icon || app.appId,
                cmd: app.cmd || app.appId
            })
        }
        pinnedApps = list
        savePinnedApps()
    }

    function reorderPinnedApps(fromIndex, toIndex) {
        if (fromIndex < 0 || fromIndex >= pinnedApps.length || toIndex < 0 || toIndex >= pinnedApps.length || fromIndex === toIndex) return;
        let list = Array.from(pinnedApps)
        let item = list.splice(fromIndex, 1)[0]
        list.splice(toIndex, 0, item)
        pinnedApps = list
        savePinnedApps()
    }

    function savePinnedApps() {
        let jsonStr = JSON.stringify(pinnedApps)
        saveProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/save_pinned_apps.py", jsonStr]
        saveProc.running = true
    }

    function updateIconGeometries(map) {
        if (!map || typeof map !== "object") return;
        let jsonStr = JSON.stringify(map)
        updateGeomProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/update_icon_geometries.py", jsonStr]
        updateGeomProc.running = true
    }

    Process { id: proc }
    Process { id: saveProc }
    Process { id: updateGeomProc }

    // Read saved pinned apps from JSON as a SINGLE LINE stream on startup
    Process {
        id: readPinnedProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/read_pinned_apps.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let txt = data.trim()
                if (txt === "DEFAULT" || txt === "") return;
                try {
                    let parsed = JSON.parse(txt)
                    if (parsed && Array.isArray(parsed)) {
                        root.pinnedApps = parsed
                    }
                } catch (e) {}
            }
        }
    }

    // Event-driven Active Window & Open Windows DBus Daemon
    Process {
        id: activeDaemon
        command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/services/python/active_window_service.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let txt = data.trim()
                if (txt === "TOGGLE_LAUNCHER") {
                    PopupService.toggleAppLauncher()
                }
            }
        }
    }

    // Single-line JSON State Reader Process (100ms)
    Process {
        id: readStateProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/read_window_state.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let parsed = JSON.parse(data.trim())
                    if (parsed) {
                        if (parsed.active && parsed.active !== "") {
                            root.activeAppId = parsed.active
                        }
                        if (parsed.open && Array.isArray(parsed.open)) {
                            root.openWindowApps = parsed.open
                        }
                        if (parsed.fullscreen !== undefined) {
                            root.isFullscreen = parsed.fullscreen
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // 100ms High-speed State Reader Timer
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!readStateProc.running) {
                readStateProc.running = true
            }
        }
    }

    Component.onCompleted: {
        if (!readPinnedProc.running) readPinnedProc.running = true
        if (!activeDaemon.running) activeDaemon.running = true
        if (!readStateProc.running) readStateProc.running = true
    }
}
