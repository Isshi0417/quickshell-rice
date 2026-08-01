#!/bin/bash
# Toggle Quickshell App Launcher via DBus / IPC
busctl --user call io.quickshell.ActiveApp /ActiveApp io.quickshell.ActiveApp toggleLauncher 2>/dev/null || touch /tmp/quickshell_toggle_launcher
