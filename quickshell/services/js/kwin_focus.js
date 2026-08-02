// KWin JavaScript Script: Focus, Restore, or Cycle Application Windows
var name = "%APP_NAME%".toLowerCase().trim();
var ix = %ICON_X%;
var iy = %ICON_Y%;

if (name && name !== "") {
    var windows = workspace.windowList();
    var matchingWindows = [];

    for (var i = 0; i < windows.length; i++) {
        var win = windows[i];
        if (!win.normalWindow && !win.fullScreen && !win.managed) continue;

        var cls = (win.desktopFileName || win.resourceClass || win.resourceName || "").toLowerCase().trim();
        var caption = (win.caption || "").toLowerCase().trim();
        if (!cls && !caption) continue;

        var matches = false;

        if (cls === name) {
            matches = true;
        } else if (name.indexOf("overwatch") !== -1 || name.indexOf("2357570") !== -1) {
            if (cls.indexOf("overwatch") !== -1 || caption.indexOf("overwatch") !== -1 || cls === "steam_app_2357570") {
                matches = true;
            }
        } else if (name.indexOf("steam_app_") !== -1) {
            if (cls === name || cls.indexOf(name) !== -1) {
                matches = true;
            }
        } else if (name !== "steam") {
            if (cls && cls !== "steam" && (cls.indexOf(name) !== -1 || name.indexOf(cls) !== -1)) {
                matches = true;
            } else if (caption && caption.indexOf(name) !== -1) {
                matches = true;
            }
        }

        if (matches) {
            matchingWindows.push(win);
        }
    }

    if (matchingWindows.length === 1) {
        var targetWin = matchingWindows[0];
        try { targetWin.setMinimizeIconGeometry(Qt.rect(ix, iy, 42, 42)); } catch(e) {}

        if (workspace.activeWindow === targetWin && !targetWin.minimized) {
            targetWin.minimized = true;
        } else {
            targetWin.minimized = false;
            workspace.activeWindow = targetWin;
        }
    } else if (matchingWindows.length > 1) {
        var activeIdx = -1;
        for (var j = 0; j < matchingWindows.length; j++) {
            if (workspace.activeWindow === matchingWindows[j] && !matchingWindows[j].minimized) {
                activeIdx = j;
                break;
            }
        }

        var nextIdx = 0;
        if (activeIdx !== -1) {
            nextIdx = (activeIdx + 1) % matchingWindows.length;
        }

        var winToActivate = matchingWindows[nextIdx];
        try { winToActivate.setMinimizeIconGeometry(Qt.rect(ix, iy, 42, 42)); } catch(e) {}
        winToActivate.minimized = false;
        workspace.activeWindow = winToActivate;
    }
}
