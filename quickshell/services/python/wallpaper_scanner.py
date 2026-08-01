#!/usr/bin/env python3
import os
import json
import sys

def scan_wallpapers():
    search_dirs = [
        os.path.expanduser('~/Pictures/Wallpapers'),
        os.path.expanduser('~/.config/quickshell/wallpapers'),
        '/usr/share/wallpapers',
        '/usr/share/backgrounds'
    ]
    res = []
    seen = set()

    for base_dir in search_dirs:
        if not os.path.exists(base_dir):
            continue
        for root, dirs, files in os.walk(base_dir):
            for filename in files:
                if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.webp', '.svg')):
                    full_path = os.path.join(root, filename)
                    if full_path in seen:
                        continue
                    seen.add(full_path)
                    
                    variant_name = os.path.basename(root) if root != base_dir else os.path.splitext(filename)[0]
                    res.append({
                        'variant': variant_name,
                        'name': filename,
                        'path': full_path
                    })

    res.sort(key=lambda x: (x['variant'].lower(), x['name'].lower()))
    print(json.dumps(res), flush=True)

if __name__ == '__main__':
    scan_wallpapers()
