pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // All parsed desktop apps
    property var allApps: []

    // Category list — deduplicated by display label ("All" always first)
    readonly property var categories: {
        let cats = []
        let seen = {}
        for (let i = 0; i < allApps.length; i++) {
            let appCats = allApps[i].categories || []
            for (let j = 0; j < appCats.length; j++) {
                let rawKey = appCats[j].trim()
                let displayName = knownCategories[rawKey]
                if (displayName && !seen[displayName]) {
                    seen[displayName] = true
                    cats.push(displayName)
                }
            }
        }
        cats.sort((a, b) => a.localeCompare(b))
        return ["All"].concat(cats)
    }

    // Human-readable labels for XDG category keys
    readonly property var knownCategories: ({
        "AudioVideo":    "Sound & Video",
        "Audio":         "Sound & Video",
        "Video":         "Sound & Video",
        "Development":   "Development",
        "Education":     "Education",
        "Game":          "Games",
        "Games":         "Games",
        "Graphics":      "Graphics",
        "Network":       "Internet",
        "Internet":      "Internet",
        "Office":        "Office",
        "Science":       "Science",
        "Settings":      "Settings",
        "System":        "System",
        "Utility":       "Utilities",
        "Utilities":     "Utilities"
    })

    property string activeCategory: "All"
    property string searchQuery: ""

    // Filtered app list
    readonly property var filteredApps: {
        let q = searchQuery.toLowerCase().trim()
        let result = []
        for (let i = 0; i < allApps.length; i++) {
            let app = allApps[i]

            // Category filter
            if (activeCategory !== "All") {
                let inCat = false
                let appCats = app.categories || []
                for (let j = 0; j < appCats.length; j++) {
                    let rawKey = appCats[j].trim()
                    let displayName = knownCategories[rawKey] || rawKey
                    if (displayName === activeCategory || rawKey === activeCategory) {
                        inCat = true
                        break
                    }
                }
                if (!inCat) continue
            }

            // Search filter
            if (q && !app.name.toLowerCase().includes(q)) continue

            result.push(app)
        }
        // Sort alphabetically
        result.sort((a, b) => a.name.localeCompare(b.name))
        return result
    }

    function launch(app) {
        if (!app || !app.exec) return
        // Strip desktop-file field codes (%u %U %f %F etc.)
        let cmd = app.exec.replace(/%[a-zA-Z]/g, "").trim()
        TaskService.launchApp(cmd)
    }

    function reset() {
        activeCategory = "All"
        searchQuery = ""
    }

    // Fallback icon path from active system icon theme
    property string fallbackIconPath: ""

    Process { id: launchProc }

    // Parse desktop files on startup and monitor real-time directory changes
    Process {
        id: parseProc
        command: ["python3", "-u", "/home/sho/Documents/themes/quickshell/services/python/app_launcher_service.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let parsed = JSON.parse(data.trim())
                    if (parsed && typeof parsed === "object") {
                        if (parsed.fallback) root.fallbackIconPath = parsed.fallback
                        if (parsed.apps && Array.isArray(parsed.apps)) root.allApps = parsed.apps
                    }
                } catch (e) {}
            }
        }
    }

    function reload() {
        if (parseProc.running) {
            parseProc.write("reload\n")
        } else {
            parseProc.running = true
        }
    }
}
