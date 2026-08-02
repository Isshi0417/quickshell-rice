// KWin JavaScript Script: Gracefully Close Specific Window Instance
var targetId = "%WIN_ID%".trim();
var targetQuery = "%TARGET_QUERY%".toLowerCase().trim();

if (targetId || targetQuery) {
    var windows = workspace.windowList();
    for (var i = 0; i < windows.length; i++) {
        var win = windows[i];
        var id = String(win.internalId || win.windowId || "");
        var cls = (win.desktopFileName || win.resourceClass || win.resourceName || "").toLowerCase().trim();
        var caption = (win.caption || "").toLowerCase().trim();

        var matches = false;
        if (targetId && id && (id === targetId || id.indexOf(targetId) !== -1)) {
            matches = true;
        }
        if (!matches && targetQuery) {
            if (caption && caption.indexOf(targetQuery) !== -1) {
                matches = true;
            } else if (cls && cls.indexOf(targetQuery) !== -1) {
                matches = true;
            }
        }

        if (matches) {
            win.closeWindow();
            break;
        }
    }
}
