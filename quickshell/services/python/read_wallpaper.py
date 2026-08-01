#!/usr/bin/env python3
import json
import os

def read_wallpaper():
    user_file = os.path.expanduser('~/.config/quickshell_user_wallpaper.json')
    if os.path.exists(user_file):
        try:
            with open(user_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                if isinstance(data, dict) and data.get("wallpaper"):
                    print(json.dumps(data), flush=True)
                    return
        except Exception:
            pass
    print(json.dumps({"wallpaper": ""}), flush=True)

if __name__ == '__main__':
    read_wallpaper()
