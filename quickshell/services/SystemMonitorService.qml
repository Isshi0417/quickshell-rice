pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int cpuPct: 0
    property real cpuTemp: 0.0
    property int cpuFan: 0
    property string cpuFreq: "4.0 GHz"
    property int cpuCores: 8
    property var cpuHistory: [10, 10, 10, 10, 10, 10, 10, 10, 10, 10]

    property int gpuPct: 0
    property real gpuTemp: 0.0
    property int gpuVramUsed: 0
    property int gpuVramTotal: 8188
    property string gpuPower: "20W / 78W"
    property int gpuFan: 0
    property var gpuHistory: [5, 5, 5, 5, 5, 5, 5, 5, 5, 5]

    property real nvmeTemp: 0.0
    property real wifiTemp: 0.0

    property real ramUsed: 0.0
    property real ramTotal: 30.6
    property int ramPct: 0
    property var ramHistory: [20, 20, 20, 20, 20, 20, 20, 20, 20, 20]

    property real swapUsed: 0.0
    property real swapTotal: 8.0

    property real diskUsed: 0.0
    property real diskTotal: 500.0
    property int diskPct: 0

    property string netRx: "0 B/s"
    property string netTx: "0 B/s"
    property string uptime: "0m"

    property string topProc: "systemd (1%)"
    property int procCount: 250

    Process {
        id: monitorProc
        command: ["python3", "-u", "/home/sho/Documents/themes/quickshell/services/python/system_monitor_service.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let parsed = JSON.parse(data.trim())
                    if (parsed && typeof parsed === "object") {
                        if (parsed.cpu !== undefined) root.cpuPct = parsed.cpu
                        if (parsed.cpu_temp !== undefined) root.cpuTemp = parsed.cpu_temp
                        if (parsed.cpu_fan !== undefined) root.cpuFan = parsed.cpu_fan
                        if (parsed.cpu_freq !== undefined) root.cpuFreq = parsed.cpu_freq
                        if (parsed.cpu_cores !== undefined) root.cpuCores = parsed.cpu_cores
                        if (parsed.cpu_history !== undefined) root.cpuHistory = parsed.cpu_history

                        if (parsed.gpu_pct !== undefined) root.gpuPct = parsed.gpu_pct
                        if (parsed.gpu_temp !== undefined) root.gpuTemp = parsed.gpu_temp
                        if (parsed.gpu_vram_used !== undefined) root.gpuVramUsed = parsed.gpu_vram_used
                        if (parsed.gpu_vram_total !== undefined) root.gpuVramTotal = parsed.gpu_vram_total
                        if (parsed.gpu_power !== undefined) root.gpuPower = parsed.gpu_power
                        if (parsed.gpu_fan !== undefined) root.gpuFan = parsed.gpu_fan
                        if (parsed.gpu_history !== undefined) root.gpuHistory = parsed.gpu_history

                        if (parsed.nvme_temp !== undefined) root.nvmeTemp = parsed.nvme_temp
                        if (parsed.wifi_temp !== undefined) root.wifiTemp = parsed.wifi_temp

                        if (parsed.ram_used !== undefined) root.ramUsed = parsed.ram_used
                        if (parsed.ram_total !== undefined) root.ramTotal = parsed.ram_total
                        if (parsed.ram_pct !== undefined) root.ramPct = parsed.ram_pct
                        if (parsed.ram_history !== undefined) root.ramHistory = parsed.ram_history
                        if (parsed.swap_used !== undefined) root.swapUsed = parsed.swap_used
                        if (parsed.swap_total !== undefined) root.swapTotal = parsed.swap_total

                        if (parsed.disk_used !== undefined) root.diskUsed = parsed.disk_used
                        if (parsed.disk_total !== undefined) root.diskTotal = parsed.disk_total
                        if (parsed.disk_pct !== undefined) root.diskPct = parsed.disk_pct

                        if (parsed.net_rx !== undefined) root.netRx = parsed.net_rx
                        if (parsed.net_tx !== undefined) root.netTx = parsed.net_tx
                        if (parsed.uptime !== undefined) root.uptime = parsed.uptime

                        if (parsed.top_proc !== undefined) root.topProc = parsed.top_proc
                        if (parsed.proc_count !== undefined) root.procCount = parsed.proc_count
                    }
                } catch (e) {}
            }
        }
    }
}
