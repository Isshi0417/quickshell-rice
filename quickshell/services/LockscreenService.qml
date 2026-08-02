pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isLocked: false
    property string userPassword: ""
    property bool isAuthenticating: false
    property bool authFailed: false
    property string authErrorMsg: ""
    property int typedCount: 0
    property string username: ""
    property string realName: ""

    // Signal emitted whenever a key is typed to trigger animated dot entry/bounce
    signal keyTyped(string char)
    signal keyDeleted()

    Timer {
        id: resetErrorTimer
        interval: 2000
        repeat: false
        onTriggered: {
            root.authFailed = false
            root.authErrorMsg = ""
        }
    }

    Component.onCompleted: {
        usernameProc.running = true
    }

    Process {
        id: usernameProc
        command: ["whoami"]
        stdout: SplitParser {
            onRead: data => {
                let u = data.trim()
                if (u !== "") root.username = u
            }
        }
    }

    function lock() {
        userPassword = ""
        typedCount = 0
        authFailed = false
        authErrorMsg = ""
        isLocked = true
    }

    function unlock() {
        userPassword = ""
        typedCount = 0
        authFailed = false
        authErrorMsg = ""
        isLocked = false
    }

    function appendChar(ch) {
        if (isAuthenticating) return;
        authFailed = false
        userPassword += ch
        typedCount = userPassword.length
        root.keyTyped(ch)
    }

    function backspace() {
        if (isAuthenticating) return;
        authFailed = false
        if (userPassword.length > 0) {
            userPassword = userPassword.substring(0, userPassword.length - 1)
            typedCount = userPassword.length
            root.keyDeleted()
        }
    }

    function clearPassword() {
        userPassword = ""
        typedCount = 0
    }

    function submitPassword() {
        if (isAuthenticating || userPassword === "") return;
        isAuthenticating = true
        authFailed = false
        authErrorMsg = ""

        authProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/services/python/lockscreen_auth_service.py", userPassword]
        authProc.running = true
    }

    Process {
        id: authProc
        onExited: (code, exitStatus) => {
            root.isAuthenticating = false
            if (code === 0) {
                root.unlock()
            } else {
                root.authFailed = true
                root.authErrorMsg = "Incorrect password"
                root.clearPassword()
                resetErrorTimer.restart()
            }
        }
    }
}
