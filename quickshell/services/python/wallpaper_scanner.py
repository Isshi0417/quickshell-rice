#!/usr/bin/env python3
import os
import json
import sys

def scan_wallpapers():
    base_dir = os.path.expanduser('~/Pictures/Wallpapers')
    res = []

    if os.path.exists(base_dir):
        for root, dirs, files in os.walk(base_dir):
            rel_variant = os.path.relpath(root, base_dir)
            if rel_variant != '.':
                for filename in files:
                    if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.webp', '.svg')):
                        res.append({
                            'variant': rel_variant,
                            'name': filename,
                            'path': os.path.join(root, filename)
                        })

    res.sort(key=lambda x: (x['variant'], x['name']))
    print(json.dumps(res), flush=True)

if __name__ == '__main__':
    scan_wallpapers()
