#!/usr/bin/env python3
import sys
import os
import subprocess

JS_TEMPLATE_PATH = os.path.expanduser('~/.config/quickshell/services/js/kwin_close.js')

def close_window(win_id="", target_query=""):
    try:
        with open(JS_TEMPLATE_PATH, 'r', encoding='utf-8') as f:
            template = f.read()

        script = template.replace('%WIN_ID%', win_id).replace('%TARGET_QUERY%', target_query)
        
        target_js = '/tmp/kwin_close.js'
        with open(target_js, 'w', encoding='utf-8') as f:
            f.write(script)

        # Unload previous script instance to prevent KWin memory leaks
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
    win_id = sys.argv[1] if len(sys.argv) >= 2 else ""
    target_query = sys.argv[2] if len(sys.argv) >= 3 else ""
    close_window(win_id, target_query)
