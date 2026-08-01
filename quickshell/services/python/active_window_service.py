#!/usr/bin/env python3
import os
import sys
import glob
import json
import time
import subprocess
import shutil
import configparser
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

ACTIVE_FILE = "/tmp/quickshell_active_app.txt"
OPEN_WINS_FILE = "/tmp/quickshell_open_windows.json"

_icon_cache = {}

def get_icon_search_dirs():
    theme = 'hicolor'
    kde_cfg = os.path.expanduser('~/.config/kdeglobals')
    if os.path.exists(kde_cfg):
        cp = configparser.ConfigParser(interpolation=None)
        try:
            cp.read(kde_cfg)
            t = cp.get('Icons', 'Theme', fallback=None)
            if t: theme = t
        except Exception: pass

    themes_to_search = [theme]
    def add_inherits(t_name):
        for base in [os.path.expanduser('~/.local/share/icons'), '/usr/share/icons']:
            idx = os.path.join(base, t_name, 'index.theme')
            if os.path.exists(idx):
                cp = configparser.ConfigParser(interpolation=None)
                try:
                    cp.read(idx)
                    inh = cp.get('Icon Theme', 'Inherits', fallback='')
                    for parent in inh.split(','):
                        parent = parent.strip()
                        if parent and parent not in themes_to_search:
                            themes_to_search.append(parent)
                            add_inherits(parent)
                except Exception: pass

    add_inherits(theme)
    for fallback_theme in ['hicolor', 'breeze', 'Papirus', 'Adwaita']:
        if fallback_theme not in themes_to_search:
            themes_to_search.append(fallback_theme)

    dirs = []
    bases = [os.path.expanduser('~/.local/share/icons'), '/usr/share/icons']
    subdirs = [
        '64x64/apps', '48x48/apps', 'scalable/apps', '128x128/apps', '256x256/apps', '32x32/apps',
        '64x64@2x/apps', '48x48@2x/apps', 'apps/64', 'apps/48', 'apps/scalable', 'apps'
    ]

    for t in themes_to_search:
        for b in bases:
            for sd in subdirs:
                d = os.path.join(b, t, sd)
                if os.path.exists(d) and d not in dirs:
                    dirs.append(d)

    dirs.append('/usr/share/pixmaps')
    return dirs

_search_dirs = get_icon_search_dirs()

def parse_desktop(f):
    entry = {}
    in_desktop = False
    try:
        with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
            for line in fp:
                line = line.strip()
                if not line or line.startswith('#'): continue
                if line.startswith('['):
                    in_desktop = (line == '[Desktop Entry]')
                    continue
                if in_desktop and '=' in line:
                    k, v = line.split('=', 1)
                    k = k.strip()
                    if k not in entry:
                        entry[k] = v.strip()
    except Exception: pass
    return entry

def resolve_game_info(app_lower):
    # Handle Steam Apps (e.g. steam_app_1245620 or steam_app_570)
    if 'steam_app_' in app_lower:
        parts = app_lower.split('steam_app_')
        if len(parts) > 1:
            steam_id = parts[1].split('.')[0]
            game_name = None
            game_icon = None

            # 1. Search for steam_app_<id>.desktop
            desktop_paths = glob.glob(os.path.expanduser(f'~/.local/share/applications/*{steam_id}*.desktop')) + \
                            glob.glob(f'/usr/share/applications/*{steam_id}*.desktop')
            for dp in desktop_paths:
                entry = parse_desktop(dp)
                if entry:
                    game_name = entry.get('Name')
                    game_icon = entry.get('Icon')
                    if game_name: break

            # 2. Search Steam App Manifest VDF files
            if not game_name:
                vdf_paths = glob.glob(os.path.expanduser(f'~/.steam/root/steamapps/appmanifest_{steam_id}.vdf')) + \
                            glob.glob(os.path.expanduser(f'~/.local/share/Steam/steamapps/appmanifest_{steam_id}.vdf')) + \
                            glob.glob(os.path.expanduser(f'~/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/appmanifest_{steam_id}.vdf'))
                for vp in vdf_paths:
                    try:
                        with open(vp, 'r', encoding='utf-8', errors='ignore') as f:
                            for line in f:
                                if '"name"' in line:
                                    game_name = line.split('"name"')[1].replace('"', '').strip()
                                    break
                    except Exception: pass

            if not game_icon:
                icon_candidates = glob.glob(os.path.expanduser(f'~/.steam/root/steam/games/*{steam_id}*.png')) + \
                                  glob.glob(os.path.expanduser(f'~/.local/share/Steam/steam/games/*{steam_id}*.png')) + \
                                  glob.glob(os.path.expanduser(f'~/.var/app/com.valvesoftware.Steam/data/Steam/steam/games/*{steam_id}*.png'))
                if icon_candidates:
                    game_icon = icon_candidates[0]
                else:
                    game_icon = "com.valvesoftware.Steam"

            if not game_name:
                game_name = f"Steam Game ({steam_id})"

            return {
                "appId": app_lower,
                "name": game_name,
                "icon": game_icon
            }

    # Handle Lutris games
    if 'lutris' in app_lower:
        lutris_desktops = glob.glob(os.path.expanduser('~/.local/share/applications/lutris-*.desktop'))
        for ld in lutris_desktops:
            entry = parse_desktop(ld)
            if entry and entry.get('Name'):
                return {
                    "appId": app_lower,
                    "name": entry.get('Name'),
                    "icon": entry.get('Icon') or "net.lutris.Lutris"
                }

    # Handle Wine / Proton / Gamescope generic titles
    if app_lower in ['wine', 'wine64', 'proton', 'gamescope']:
        return {
            "appId": app_lower,
            "name": app_lower.capitalize() + " Game",
            "icon": "com.valvesoftware.Steam"
        }

    return None

def resolve_app_info(app_id):
    if not app_id:
        return {"appId": "", "name": "Application", "icon": ""}

    app_lower = app_id.lower().strip()
    if app_lower in _icon_cache:
        return _icon_cache[app_lower]

    game_info = resolve_game_info(app_lower)
    if game_info:
        _icon_cache[app_lower] = game_info
        return game_info

    desktop_files = (
        glob.glob('/usr/share/applications/*.desktop') +
        glob.glob('/usr/share/applications/**/*.desktop', recursive=True) +
        glob.glob(os.path.expanduser('~/.local/share/applications/*.desktop')) +
        glob.glob(os.path.expanduser('~/.local/share/applications/**/*.desktop'), recursive=True)
    )

    icon_name = None
    app_name = None

    for df in desktop_files:
        basename = os.path.basename(df).lower()
        base_no_ext = basename.replace('.desktop', '')
        if app_lower == base_no_ext or app_lower in basename or base_no_ext in app_lower:
            entry = parse_desktop(df)
            if entry:
                if 'Icon' in entry and not icon_name:
                    icon_name = entry['Icon']
                if 'Name' in entry and not app_name:
                    app_name = entry['Name']
                if icon_name and app_name:
                    break

    if not icon_name:
        icon_name = app_lower
    if not app_name:
        clean = app_lower.split('.')[-1].replace('-', ' ').replace('_', ' ')
        app_name = clean.title()

    resolved_icon_path = ""
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        resolved_icon_path = icon_name
    else:
        for d in _search_dirs:
            if not os.path.exists(d): continue
            for ext in ['.svg', '.png', '.xpm']:
                target = os.path.join(d, icon_name + ext)
                if os.path.exists(target):
                    resolved_icon_path = target
                    break
                matches = glob.glob(os.path.join(d, f'*{icon_name}*{ext}'))
                if matches:
                    resolved_icon_path = matches[0]
                    break
            if resolved_icon_path:
                break

    if not resolved_icon_path:
        resolved_icon_path = icon_name

    info = {
        "appId": app_lower,
        "name": app_name,
        "icon": resolved_icon_path
    }
    _icon_cache[app_lower] = info
    return info

FULLSCREEN_FILE = "/tmp/quickshell_is_fullscreen.txt"

class ActiveAppService(dbus.service.Object):
    def __init__(self, bus_name):
        super().__init__(bus_name, "/ActiveApp")

    @dbus.service.method("io.quickshell.ActiveApp", in_signature="sss")
    def updateState(self, active_app, open_windows_json, is_fullscreen_str="false"):
        try:
            with open(ACTIVE_FILE, "w") as f:
                f.write(str(active_app).strip().lower())
            
            with open(FULLSCREEN_FILE, "w") as f:
                f.write("1" if str(is_fullscreen_str).strip().lower() == "true" else "0")

            raw_wins = json.loads(open_windows_json)
            enriched_wins = []
            for app_id in raw_wins:
                enriched_wins.append(resolve_app_info(app_id))

            with open(OPEN_WINS_FILE, "w") as f:
                f.write(json.dumps(enriched_wins))
        except Exception:
            pass
        return True

    @dbus.service.method("io.quickshell.ActiveApp")
    def toggleLauncher(self):
        try:
            print("TOGGLE_LAUNCHER", flush=True)
        except Exception:
            pass
        return True

def setup_kwin_listener():
    js_template = os.path.expanduser("~/.config/quickshell/services/js/kwin_state_listener.js")
    js_path = "/tmp/kwin_state_listener.js"
    try:
        if os.path.exists(js_template):
            shutil.copyfile(js_template, js_path)
        
        # Unload previous script instance to prevent KWin memory leaks & duplicate listeners
        subprocess.run(
            ["busctl", "--user", "call", "org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "unloadScript", "s", js_path],
            capture_output=True
        )
        res = subprocess.check_output(
            ["busctl", "--user", "call", "org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "loadScript", "s", js_path],
            text=True, stderr=subprocess.DEVNULL
        )
        sid = res.strip().split()[-1]
        subprocess.check_output(
            ["busctl", "--user", "call", "org.kde.KWin", f"/Scripting/Script{sid}", "org.kde.kwin.Script", "run"],
            text=True, stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

def main():
    try:
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus_name = dbus.service.BusName("io.quickshell.ActiveApp", bus=dbus.SessionBus())
        service = ActiveAppService(bus_name)
        setup_kwin_listener()
        
        loop = GLib.MainLoop()
        loop.run()
    except Exception:
        pass

if __name__ == "__main__":
    main()
