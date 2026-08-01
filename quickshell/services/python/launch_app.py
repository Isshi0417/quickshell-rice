#!/usr/bin/env python3
import sys
import os
import subprocess
import shutil
import re

def launch():
    if len(sys.argv) < 2:
        return
    cmd = sys.argv[1].strip()
    if not cmd:
        return

    # Strip desktop field codes (%u, %U, %f, %F, etc.)
    clean_cmd = re.sub(r'%[a-zA-Z]', '', cmd).strip()
    base_name = clean_cmd.replace('.desktop', '').strip()
    lower_name = base_name.lower()

    flatpak_mappings = {
        "spotify": "com.spotify.Client",
        "feishin": "io.github.jeffvli.feishin",
        "zen": "io.github.zen_browser.zen",
        "zen-browser": "io.github.zen_browser.zen",
        "vesktop": "dev.vencord.Vesktop",
        "discord": "com.discordapp.Discord",
        "code": "com.visualstudio.code",
        "vscodium": "com.vscodium.codium",
        "obs": "com.obsproject.Studio",
        "steam": "com.valvesoftware.Steam",
        "heroic": "com.heroicgameslauncher.hgl"
    }

    # 1. Flatpak launch check (launch exactly once if Flatpak ID is installed)
    candidates_flatpak = []
    if base_name in flatpak_mappings:
        candidates_flatpak.append(flatpak_mappings[base_name])
    if lower_name in flatpak_mappings:
        candidates_flatpak.append(flatpak_mappings[lower_name])
    if base_name.startswith(("org.", "io.", "com.", "app.")):
        candidates_flatpak.append(base_name)

    for fp_id in candidates_flatpak:
        check = subprocess.run(["flatpak", "info", fp_id], capture_output=True, text=True)
        if check.returncode == 0:
            subprocess.Popen(["flatpak", "run", fp_id], start_new_session=True)
            return

    # 2. GTK Desktop launcher check
    if shutil.which("gtk-launch"):
        for gtk_id in [base_name, f"{base_name}.desktop"]:
            res = subprocess.run(["gtk-launch", gtk_id], capture_output=True, text=True)
            if res.returncode == 0:
                return

    # 3. Direct binary execution
    bin_name = clean_cmd.split()[0]
    if shutil.which(bin_name):
        subprocess.Popen(clean_cmd, shell=True, start_new_session=True)
        return

    # 4. Fallback execution
    subprocess.Popen(f"{clean_cmd} &", shell=True, start_new_session=True)

if __name__ == '__main__':
    launch()
