import Quickshell
import "../Common"
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Top bar, one per screen (see the Variants in shell.qml). Replaces waybar:
// same pills, colors and clicks, but themed live and fed by Quickshell's
// services instead of polling scripts. Same geometry as waybar (33px tall at
// y=2, 8px side margins), so windows keep their positions.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins { top: 2; left: 8; right: 8 }
    implicitHeight: 33
    color: "transparent"

    // Keep-awake: an idle inhibitor needs a visible surface, and the bar always is.
    IdleInhibitor { window: bar; enabled: root.keepAwake }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // This screen's regular workspaces in number order (special ones hidden).
    readonly property var workspaces: {
        var all = Hyprland.workspaces.values
        var out = []
        for (var i = 0; i < all.length; i++) {
            var ws = all[i]
            if (ws.id > 0 && ws.monitor && ws.monitor.name === bar.screen.name) out.push(ws)
        }
        out.sort(function(a, b) { return a.id - b.id })
        return out
    }

    readonly property bool wifiConnected: {
        var devs = Networking.devices.values
        for (var i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi && devs[i].connected) return true
        return false
    }
    readonly property bool btConnected: {
        var a = Bluetooth.defaultAdapter
        if (!a || !a.enabled) return false
        var devs = a.devices.values
        for (var i = 0; i < devs.length; i++) if (devs[i].connected) return true
        return false
    }

    readonly property string mediaText: {
        var p = root.activePlayer
        if (!p || !p.trackTitle) return ""
        var t = p.trackArtist ? p.trackArtist + " - " + p.trackTitle : p.trackTitle
        return t.length > 40 ? t.slice(0, 39) + "…" : t
    }

    // Hyprland's Lua config (0.56+) only understands Lua dispatchers.
    function focusWorkspace(target) {
        Hyprland.dispatch(Hyprland.usingLua ? 'hl.dsp.focus({ workspace = "' + target + '" })'
                                            : "workspace " + target)
    }

    RowLayout {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        spacing: 6

        Pill {
            text: " ."
            textColor: Theme.color1
            fontSize: 20
            onClicked: button => root.toggleLauncherTab(button === Qt.RightButton ? 1 : 0)
        }

        Pill {
            text: "󰥔 " + Qt.formatTime(clock.date, "hh:mm AP")
            textColor: Theme.color4
        }

        // Workspaces: click to switch, scroll to step through them.
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: wsRow.implicitWidth + 12
            radius: 16
            color: Theme.alpha(Theme.background, 0.75)
            visible: bar.workspaces.length > 0

            WheelHandler {
                target: null
                onWheel: event => bar.focusWorkspace(event.angleDelta.y > 0 ? "e-1" : "e+1")
            }

            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 2
                Repeater {
                    model: bar.workspaces
                    Rectangle {
                        id: wsButton
                        required property var modelData
                        readonly property bool active: modelData.active
                        height: 27
                        implicitWidth: wsLabel.implicitWidth + (active ? 32 : 12)
                        width: implicitWidth
                        radius: active ? 16 : 8
                        color: active ? Theme.alpha(Theme.color5, 0.75)
                            : wsMouse.containsMouse ? Theme.alpha(Theme.color5, 0.4) : "transparent"
                        Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                        StyledText {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: wsButton.modelData.name
                            font.pixelSize: 11
                            font.bold: true
                            color: wsButton.active ? Theme.background
                                : wsButton.modelData.urgent ? Theme.color1
                                : wsMouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.3)
                        }
                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wsButton.modelData.activate()
                        }
                    }
                }
            }
        }
    }

    // Now playing: click to play/pause, right-click for the music panel.
    Pill {
        anchors.centerIn: parent
        visible: bar.mediaText !== ""
        text: bar.mediaText
        textColor: Theme.color2
        onClicked: button => {
            if (button === Qt.RightButton) root.toggleMusic()
            else if (root.activePlayer) root.activePlayer.togglePlaying()
        }
    }

    RowLayout {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        spacing: 6

        Pill {
            visible: root.keepAwake
            text: "󰅶"
            textColor: Theme.color3
            fontSize: 14
            onClicked: root.keepAwake = false
        }

        Pill {
            visible: Battery.present
            text: Battery.glyph + " " + Battery.percent + "%"
            textColor: Battery.low ? Theme.color1 : Battery.pluggedIn ? Theme.color2 : Theme.color13
        }

        // Volume: click to mute, scroll to adjust, right-click for the mixer.
        Pill {
            text: Audio.glyph + " " + (Audio.muted ? "mute" : Audio.volume + "%")
            textColor: Theme.color6
            onClicked: button => {
                if (button === Qt.RightButton) root.toggleAudio()
                else Audio.toggleMute()
            }
            onScrolled: delta => Audio.setVolume(Math.min(100, Audio.volume + (delta > 0 ? 2 : -2)))
        }

        // Network: click for Wi-Fi, right-click for Bluetooth.
        Pill {
            text: (bar.wifiConnected ? "  " : "󰖪 ") + (bar.btConnected ? "󰂱" : "󰂲")
            onClicked: button => {
                if (button === Qt.RightButton) root.toggleBluetooth()
                else root.toggleWifi()
            }
        }

        Pill {
            text: "󰍜"
            textColor: Theme.color1
            fontSize: 20
            onClicked: root.toggleDashboard()
        }
    }

    // A rounded module like waybar's: translucent, brighter on hover.
    component Pill: Rectangle {
        id: pill
        property alias text: label.text
        property color textColor: Theme.foreground
        property int fontSize: 11
        signal clicked(int button)
        signal scrolled(int delta)
        Layout.fillHeight: true
        implicitWidth: label.implicitWidth + 24
        implicitHeight: 33
        radius: 16
        color: Theme.alpha(Theme.background, area.containsMouse ? 0.95 : 0.75)
        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }
        StyledText {
            id: label
            anchors.centerIn: parent
            color: pill.textColor
            font.pixelSize: pill.fontSize
            font.bold: true
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => pill.clicked(mouse.button)
            onWheel: wheel => pill.scrolled(wheel.angleDelta.y)
        }
    }
}
