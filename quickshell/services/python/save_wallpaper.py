#!/usr/bin/env python3
import json
import os
import sys

def save_wallpaper():
    if len(sys.argv) < 2:
        return
    wp_path = sys.argv[1]
    user_file = os.path.expanduser('~/.config/quickshell_user_wallpaper.json')
    data = {"wallpaper": wp_path}
    try:
        with open(user_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
    except Exception:
        pass

if __name__ == '__main__':
    save_wallpaper()
