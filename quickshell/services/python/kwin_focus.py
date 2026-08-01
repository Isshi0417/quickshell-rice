#!/usr/bin/env python3
import sys
import os
import subprocess

JS_TEMPLATE_PATH = os.path.expanduser('~/.config/quickshell/services/js/kwin_focus.js')

def focus_window(app_name, ix=0, iy=0):
    try:
        with open(JS_TEMPLATE_PATH, 'r', encoding='utf-8') as f:
            template = f.read()

        script = template.replace('%APP_NAME%', app_name).replace('%ICON_X%', str(ix)).replace('%ICON_Y%', str(iy))
        
        target_js = '/tmp/kwin_focus.js'
        with open(target_js, 'w', encoding='utf-8') as f:
            f.write(script)

        # Always unload previous script instance to prevent KWin memory leaks
        subprocess.run(['busctl', '--user', 'call', 'org.kde.KWin', '/Scripting', 'org.kde.kwin.Scripting', 'unloadScript', 's', target_js], capture_output=True)

        res = subprocess.check_output(
            ['busctl', '--user', 'call', 'org.kde.KWin', '/Scripting', 'org.kde.kwin.Scripting', 'loadScript', 's', target_js],
            text=True
        )
        sid = res.strip().split()[-1]
        subprocess.run(['busctl', '--user', 'call', 'org.kde.KWin', f'/Scripting/Script{sid}', 'org.kde.kwin.Script', 'run'], capture_output=True)
        subprocess.run(['busctl', '--user', 'call', 'org.kde.KWin', f'/Scripting/Script{sid}', 'org.kde.kwin.Script', 'stop'], capture_output=True)
        subprocess.run(['busctl', '--user', 'call', 'org.kde.KWin', '/Scripting', 'org.kde.kwin.Scripting', 'unloadScript', 's', target_js], capture_output=True)
    except Exception:
        pass

if __name__ == '__main__':
    if len(sys.argv) >= 2:
        app_name = sys.argv[1]
        ix = sys.argv[2] if len(sys.argv) >= 3 else 0
        iy = sys.argv[3] if len(sys.argv) >= 4 else 0
        focus_window(app_name, ix, iy)
