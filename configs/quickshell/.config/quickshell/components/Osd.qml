import Quickshell
import "../Common"
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Volume / brightness on-screen display. Volume follows the default Pipewire
// sink and brightness follows backlight uevents, so the media keys (or any
// other tool) trigger it without rebinding anything. Stays quiet while the
// dashboard or audio panel is open, since those show their own sliders.
PanelWindow {
    id: osd
    anchors.bottom: true
    margins.bottom: 80
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 280
    implicitHeight: 52
    color: "transparent"
    mask: Region {}  // click-through
    visible: content.opacity > 0

    property string kind: "volume"
    property int value: 0
    property bool muted: false
    property bool shown: false
    // Ignore the burst of initial property values at startup.
    property bool armed: false

    function show(k, v, m) {
        if (!armed || root.dashboardVisible || root.audioVisible) return
        kind = k
        value = v
        muted = m
        shown = true
        hideTimer.restart()
    }

    Timer { interval: 1500; running: true; onTriggered: osd.armed = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: osd.shown = false }

    // Read the sink directly: derived bindings (Audio.volume) may not have
    // updated yet when this handler runs.
    Connections {
        target: Audio.ready ? Audio.sink.audio : null
        function onVolumeChanged() { osd.showVolume() }
        function onMutedChanged() { osd.showVolume() }
    }
    function showVolume() {
        var a = Audio.sink.audio
        show("volume", Math.round(a.volume * 100), a.muted)
    }

    // The kernel emits a backlight "change" uevent on every brightness write.
    Process {
        running: true
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: line => { if (line.indexOf(" change ") >= 0) brightnessRead.request() }
        }
    }
    Process {
        id: brightnessRead
        property bool again: false
        command: ["brightnessctl", "-m"]  // name,class,current,percent%,max
        function request() {
            if (running) again = true
            else running = true
        }
        stdout: SplitParser {
            onRead: data => osd.show("brightness", parseInt(data.split(",")[3]) || 0, false)
        }
        // Key repeat fires faster than brightnessctl exits; end on the latest value.
        onExited: if (again) { again = false; running = true }
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 16
        color: Theme.alpha(Theme.background, 0.85)
        opacity: osd.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        readonly property color accent: osd.kind === "volume" ? Theme.color4 : Theme.color13

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12
            StyledText {
                Layout.preferredWidth: 22
                text: osd.kind === "volume"
                    ? (osd.muted || osd.value === 0 ? "󰝟" : osd.value < 50 ? "󰖀" : "󰕾")
                    : (osd.value < 30 ? "󰃞" : osd.value < 70 ? "󰃟" : "󰃠")
                color: content.accent
                font.pixelSize: 20
            }
            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Qt.rgba(0, 0, 0, 0.3)
                Rectangle {
                    width: parent.width * Math.min(osd.value, 100) / 100
                    height: parent.height
                    radius: 4
                    color: content.accent
                    opacity: osd.muted ? 0.35 : 1
                    Behavior on width { NumberAnimation { duration: 100 } }
                }
            }
            StyledText {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: osd.muted ? "mute" : osd.value + "%"
                color: Theme.foreground
                font.pixelSize: 12
                font.bold: true
            }
        }
    }
}
