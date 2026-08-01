// KWin JavaScript Script: Active Window, Open Windows & Fullscreen DBus Listener
function updateWindows() {
    var openApps = [];
    var actApp = "";
    var isFullscreen = false;
    var wins = workspace.windowList();
    var activeWin = workspace.activeWindow;

    if (activeWin && !activeWin.skipTaskbar) {
        actApp = (activeWin.resourceClass || activeWin.desktopFileName || "").toLowerCase();
        if (activeWin.fullScreen) {
            isFullscreen = true;
        }
    }

    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (w.fullScreen && (w.active || w === activeWin)) {
            isFullscreen = true;
        }
        if ((w.normalWindow || w.fullScreen || w.managed) && !w.skipTaskbar) {
            var cls = (w.resourceClass || w.desktopFileName || "").toLowerCase();
            if (!cls && w.caption) cls = w.caption.toLowerCase();
            if (cls && cls !== "quickshell" && cls !== "plasmashell" && cls.indexOf("status_icon") === -1 && cls.indexOf("tray") === -1 && cls.indexOf("desktop") === -1) {
                if (openApps.indexOf(cls) === -1) {
                    openApps.push(cls);
                }
            }
        }
    }

    callDBus("io.quickshell.ActiveApp", "/ActiveApp", "io.quickshell.ActiveApp", "updateState", actApp, JSON.stringify(openApps), isFullscreen ? "true" : "false");
}

workspace.windowActivated.connect(updateWindows);
workspace.windowAdded.connect(updateWindows);
workspace.windowRemoved.connect(updateWindows);
updateWindows();
