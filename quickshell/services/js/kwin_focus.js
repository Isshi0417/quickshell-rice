// KWin JavaScript Script: Focus, Restore, or Minimize Application Window
var name = "%APP_NAME%".toLowerCase().trim();
var ix = %ICON_X%;
var iy = %ICON_Y%;

if (name && name !== "") {
    var windows = workspace.windowList();
    for (var i = 0; i < windows.length; i++) {
        var win = windows[i];
        if (!win.normalWindow && !win.fullScreen && !win.managed) continue;

        var cls = (win.desktopFileName || win.resourceClass || win.resourceName || "").toLowerCase().trim();
        var caption = (win.caption || "").toLowerCase().trim();
        
        if (!cls && !caption) continue;

        var matches = false;

        // 1. Exact match check
        if (cls === name) {
            matches = true;
        }

        // 2. Overwatch & Steam game window targeting
        if (!matches && (name.indexOf("overwatch") !== -1 || name.indexOf("2357570") !== -1)) {
            if (cls.indexOf("overwatch") !== -1 || caption.indexOf("overwatch") !== -1 || cls === "steam_app_2357570") {
                matches = true;
            }
        }

        // 3. Steam App ID window targeting (must NOT match main "steam" client window)
        if (!matches && name.indexOf("steam_app_") !== -1) {
            if (cls === name || cls.indexOf(name) !== -1) {
                matches = true;
            }
        }

        // 4. General matching (exclude steam client when searching for steam_app_)
        if (!matches && name !== "steam") {
            if (cls && cls !== "steam" && (cls.indexOf(name) !== -1 || name.indexOf(cls) !== -1)) {
                matches = true;
            } else if (caption && caption.indexOf(name) !== -1) {
                matches = true;
            }
        }

        if (matches) {
            try {
                win.setMinimizeIconGeometry(Qt.rect(ix, iy, 42, 42));
            } catch(e) {}
            
            if (workspace.activeWindow === win && !win.minimized) {
                win.minimized = true;
            } else {
                win.minimized = false;
                workspace.activeWindow = win;
            }
            break;
        }
    }
}
