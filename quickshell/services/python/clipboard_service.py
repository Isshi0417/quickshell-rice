#!/usr/bin/env python3
import subprocess
import os
import hashlib
import json
import sys

def check_clipboard():
    clip_dir = '/tmp/quickshell_clip'
    os.makedirs(clip_dir, exist_ok=True)

    res = None

    # 1. Check PNG Image content in Wayland clipboard
    try:
        img_data = subprocess.check_output(
            ['wl-paste', '--type', 'image/png'],
            stderr=subprocess.DEVNULL,
            timeout=1.0
        )
        if len(img_data) > 0:
            h = hashlib.md5(img_data).hexdigest()
            path = os.path.join(clip_dir, f'{h}.png')
            if not os.path.exists(path):
                with open(path, 'wb') as f:
                    f.write(img_data)
            res = {
                'type': 'image',
                'path': path,
                'hash': h,
                'size': f'{round(len(img_data) / 1024, 1)} KB'
            }
    except Exception:
        pass

    # 2. Check Plain Text content in Wayland clipboard (if no image)
    if not res:
        try:
            txt = subprocess.check_output(
                ['wl-paste', '--type', 'text/plain', '--no-newline'],
                text=True,
                stderr=subprocess.DEVNULL,
                timeout=1.0
            )
            if txt and txt.strip():
                h = hashlib.md5(txt.encode('utf-8')).hexdigest()
                res = {
                    'type': 'text',
                    'content': txt,
                    'hash': h,
                    'length': len(txt)
                }
        except Exception:
            pass

    if res:
        print(json.dumps(res), flush=True)

if __name__ == '__main__':
    check_clipboard()
