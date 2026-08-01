pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property string playerName: ""
    property string playerDisplayName: getDisplayName(playerName)
    property string title: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property string status: "Stopped"
    property bool hasPlayer: false
    property bool isSeeking: false

    property real position: 0
    property real length: 0
    property real progress: length > 0 ? Math.min(1.0, Math.max(0.0, position / length)) : 0.0
    property string positionStr: formatTime(position)
    property string lengthStr: length > 0 ? formatTime(length) : "--:--"

    function formatTime(secs) {
        if (isNaN(secs) || secs <= 0) return "0:00"
        var m = Math.floor(secs / 60)
        var s = Math.floor(secs % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function getDisplayName(name) {
        if (!name) return ""
        let lower = name.toLowerCase()
        if (lower.indexOf("firefox") !== -1) return "Firefox"
        if (lower.indexOf("zen") !== -1) return "Zen"
        if (lower.indexOf("chrome") !== -1 || lower.indexOf("chromium") !== -1) return "Chrome"
        if (lower.indexOf("brave") !== -1) return "Brave"
        if (lower.indexOf("spotify") !== -1) return "Spotify"
        if (lower.indexOf("vlc") !== -1) return "VLC"
        if (lower.indexOf("mpv") !== -1) return "MPV"
        if (lower.indexOf("amberol") !== -1) return "Amberol"
        return name.charAt(0).toUpperCase() + name.slice(1)
    }

    function extractYouTubeArt(url) {
        if (!url) return "";
        var match = url.match(/(?:v=|\/vi\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
        if (match && match[1]) {
            return "https://img.youtube.com/vi/" + match[1] + "/hqdefault.jpg";
        }
        return "";
    }

    function playPause() {
        playPauseProc.running = true
    }

    function next() {
        nextProc.running = true
    }

    function previous() {
        prevProc.running = true
    }

    function seek(targetSec) {
        if (length > 0) {
            var validSec = Math.max(0, Math.min(length, targetSec))
            root.position = validSec
            root.isSeeking = true
            seekTimer.restart()

            var targetMicro = Math.floor(validSec * 1000000)
            seekProc.command = [
                "bash", "-c",
                "PLAYER_SERVICE=$(busctl --user list | grep -m1 'org.mpris.MediaPlayer2' | awk '{print $1}'); " +
                "TRACK_ID=$(playerctl metadata --format '{{mpris:trackid}}' | tr -d \"'\"); " +
                "[ -z \"$TRACK_ID\" ] && TRACK_ID=\"/org/mpris/MediaPlayer2/TrackList/NoTrack\"; " +
                "busctl --user call \"$PLAYER_SERVICE\" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player SetPosition ox \"$TRACK_ID\" " + targetMicro
            ]
            seekProc.running = true
        }
    }

    Timer {
        id: seekTimer
        interval: 3000
        repeat: false
        onTriggered: root.isSeeking = false
    }

    Process { id: playPauseProc; command: ["playerctl", "play-pause"] }
    Process { id: nextProc; command: ["playerctl", "next"] }
    Process { id: prevProc; command: ["playerctl", "previous"] }
    Process { id: seekProc }

    Process {
        id: statusProc
        command: ["playerctl", "status"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let stat = data.trim()
                if (stat === "Playing" || stat === "Paused" || stat === "Stopped") {
                    root.status = stat
                    root.hasPlayer = true
                } else {
                    root.status = "Stopped"
                    root.hasPlayer = false
                }
            }
        }
    }

    Process {
        id: metaProc
        command: ["playerctl", "metadata", "--format", "{{playerName}}|||{{title}}|||{{artist}}|||{{album}}|||{{mpris:artUrl}}|||{{mpris:length}}|||{{xesam:url}}"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|||")
                if (parts.length >= 5) {
                    root.playerName = parts[0] ? parts[0] : ""
                    let newTitle = parts[1] ? parts[1] : "No Title"
                    let newArtist = parts[2] ? parts[2] : "Unknown Artist"
                    let newAlbum = parts[3] ? parts[3] : ""
                    let rawArt = parts[4] ? parts[4] : ""
                    let pageUrl = parts.length >= 7 ? parts[6] : ""

                    let fetchedArt = rawArt !== "" ? rawArt : root.extractYouTubeArt(pageUrl)

                    if (newTitle !== root.title) {
                        root.title = newTitle
                        root.artist = newArtist
                        root.album = newAlbum
                        root.artUrl = fetchedArt
                        root.position = 0
                    } else {
                        if (fetchedArt !== "") {
                            root.artUrl = fetchedArt
                        }
                    }

                    if (parts.length >= 6 && parts[5] && parts[5] !== "") {
                        let lenMicro = parseFloat(parts[5])
                        if (!isNaN(lenMicro) && lenMicro > 0) {
                            root.length = lenMicro > 100000 ? lenMicro / 1000000.0 : lenMicro
                        }
                    }
                    root.hasPlayer = true
                }
            }
        }
    }

    Process {
        id: posProc
        command: ["playerctl", "position"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let posVal = parseFloat(data.trim())
                if (!isNaN(posVal) && posVal >= 0 && !seekProc.running && !root.isSeeking) {
                    root.position = posVal
                }
            }
        }
    }

    // Position sync timer
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (root.status === "Playing" && root.length > 0) {
                root.position = Math.min(root.length, root.position + 0.5)
            }
            statusProc.running = true
            metaProc.running = true
            if (!root.isSeeking) {
                posProc.running = true
            }
        }
    }
}
