#!/usr/bin/env python3
import json
import os
import sys

def read_pinned():
    p = os.path.expanduser('/home/sho/Documents/themes/quickshell/config/pinned_apps.json')
    if os.path.exists(p):
        try:
            with open(p, 'r', encoding='utf-8') as f:
                data = json.load(f)
                print(json.dumps(data), flush=True)
                return
        except Exception:
            pass
    print('DEFAULT', flush=True)

if __name__ == '__main__':
    read_pinned()
