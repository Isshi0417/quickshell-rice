// KWin JavaScript Script: Focus, Restore, or Minimize Application Window
var name = "%APP_NAME%".toLowerCase().trim();
var ix = %ICON_X%;
var iy = %ICON_Y%;

if (name && name !== "") {
    var windows = workspace.windowList();
    for (var i = 0; i < windows.length; i++) {
        var win = windows[i];
        if (!win.normalWindow || win.skipTaskbar) continue;

        var cls = (win.resourceClass || win.desktopFileName || "").toLowerCase().trim();
        var caption = (win.caption || "").toLowerCase().trim();
        
        if (!cls && !caption) continue;

        var matches = false;
        if (cls) {
            if (cls.indexOf(name) !== -1 || name.indexOf(cls) !== -1) {
                matches = true;
            }
        }
        if (!matches && caption) {
            if (caption.indexOf(name) !== -1) {
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
