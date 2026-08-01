pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string city: "Loading..."
    property real tempC: 0
    property string condition: "Clear"
    property int weatherCode: 0
    property bool isDay: true

    property string currentTempStr: Math.round(tempC) + "°C"

    function getWeatherDescription(code) {
        if (code === 0) return "Clear"
        if (code >= 1 && code <= 3) return "Partly Cloudy"
        if (code === 45 || code === 48) return "Foggy"
        if (code >= 51 && code <= 55) return "Drizzle"
        if (code >= 61 && code <= 65) return "Rainy"
        if (code >= 71 && code <= 75) return "Snowy"
        if (code >= 80 && code <= 82) return "Showers"
        if (code >= 95) return "Thunderstorm"
        return "Clear"
    }

    function fetchWeather() {
        weatherProc.running = true
    }

    Process {
        id: weatherProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/weather_service.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|||")
                if (parts.length >= 4) {
                    root.city = parts[0] ? parts[0] : "Local"
                    let tc = parseFloat(parts[1])
                    if (!isNaN(tc)) {
                        root.tempC = tc
                    }
                    let code = parseInt(parts[2])
                    if (!isNaN(code)) {
                        root.weatherCode = code
                        root.condition = root.getWeatherDescription(code)
                    }
                    root.isDay = parts[3] === "1"
                }
            }
        }
    }

    // Auto refresh every 15 minutes
    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: fetchWeather()
    }
}
