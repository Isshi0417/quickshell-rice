#!/usr/bin/env python3
import sys
import os
import subprocess
import shutil
import re

def get_installed_flatpaks():
    """Returns a list of installed Flatpak application IDs."""
    try:
        res = subprocess.run(["flatpak", "list", "--app", "--columns=application"], capture_output=True, text=True)
        if res.returncode == 0:
            return [line.strip() for line in res.stdout.splitlines() if line.strip()]
    except Exception:
        pass
    return []

def launch():
    if len(sys.argv) < 2:
        return
    raw_cmd = sys.argv[1].strip()
    if not raw_cmd:
        return

    # Strip desktop field codes (%u, %U, %f, %F, %i, %c, %k, etc.)
    clean_cmd = re.sub(r'%[a-zA-Z]', '', raw_cmd).strip()
    
    # Extract desktop ID and base name
    # e.g. "/usr/bin/equibop" -> "equibop", "org.equicord.equibop.desktop" -> "org.equicord.equibop"
    base_name = clean_cmd.replace('.desktop', '').strip()
    if '/' in base_name:
        base_name = os.path.basename(base_name.split()[0]).replace('.desktop', '').strip()
    
    lower_name = base_name.lower()

    flatpak_mappings = {
        "spotify": "com.spotify.Client",
        "feishin": "io.github.jeffvli.feishin",
        "zen": "io.github.zen_browser.zen",
        "zen-browser": "io.github.zen_browser.zen",
        "vesktop": "dev.vencord.Vesktop",
        "equibop": "org.equicord.equibop",
        "equicord": "org.equicord.equibop",
        "vencord": "dev.vencord.Vesktop",
        "discord": "com.discordapp.Discord",
        "code": "com.visualstudio.code",
        "vscodium": "com.vscodium.codium",
        "obs": "com.obsproject.Studio",
        "steam": "com.valvesoftware.Steam",
        "heroic": "com.heroicgameslauncher.hgl"
    }

    installed_flatpaks = get_installed_flatpaks()

    # 1. Flatpak launch check
    candidates_flatpak = []
    if lower_name in flatpak_mappings:
        candidates_flatpak.append(flatpak_mappings[lower_name])
    
    # Match any installed flatpak containing lower_name (e.g. 'equibop' -> 'org.equicord.equibop')
    for fp in installed_flatpaks:
        fp_lower = fp.lower()
        if lower_name in fp_lower or fp_lower.endswith(lower_name):
            if fp not in candidates_flatpak:
                candidates_flatpak.append(fp)

    if lower_name.startswith(("org.", "io.", "com.", "app.", "dev.")):
        candidates_flatpak.append(lower_name)

    for fp_id in candidates_flatpak:
        if fp_id in installed_flatpaks:
            subprocess.Popen(["flatpak", "run", fp_id], start_new_session=True)
            return
        # Fallback check via flatpak info
        check = subprocess.run(["flatpak", "info", fp_id], capture_output=True, text=True)
        if check.returncode == 0:
            subprocess.Popen(["flatpak", "run", fp_id], start_new_session=True)
            return

    # 2. GTK Desktop launcher check (using clean desktop ID without paths)
    if shutil.which("gtk-launch"):
        for gtk_id in [base_name, f"{base_name}.desktop", lower_name]:
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
