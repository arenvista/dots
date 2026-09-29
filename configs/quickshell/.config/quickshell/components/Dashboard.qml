import Quickshell
import "../Common"
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

PanelWindow {
    id: dashboard
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; right: true }
    margins { top: 40; bottom: 10; right: root.dashboardVisible ? 6 : -450 }
    implicitWidth: 420
    color: "transparent"
    WlrLayershell.keyboardFocus: root.dashboardVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    property int cpuVal: 0
    // /proc/stat jiffy counters from the previous sample, for CPU% deltas
    property real cpuPrevTotal: 0
    property real cpuPrevIdle: 0
    property int ramVal: 0
    property int diskVal: 0
    property int brightVal: 100
    property string uptimeText: "up ..."
    property var pfpFiles: []
    // Label of the power action waiting for its confirming second click.
    property string armedPower: ""

    readonly property string defaultAvatar: Paths.assets + "/pfps/pfp.jpg"
    readonly property string avatarPath: Settings.avatar !== "" ? Settings.avatar : defaultAvatar

    function formatUptime(s) {
        var d = Math.floor(s / 86400); s -= d * 86400
        var h = Math.floor(s / 3600); s -= h * 3600
        var m = Math.floor(s / 60)
        var parts = []
        if (d > 0) parts.push(d + (d === 1 ? " day" : " days"))
        if (h > 0) parts.push(h + (h === 1 ? " hour" : " hours"))
        if (m > 0 || parts.length === 0) parts.push(m + (m === 1 ? " minute" : " minutes"))
        return "up " + parts.join(", ")
    }

    // Power off / reboot / log out need a second click within 3s, so a stray
    // click can't end the session. Lock and suspend run immediately.
    function runPower(action) {
        if (action.confirm && armedPower !== action.label) {
            armedPower = action.label
            disarmTimer.restart()
            return
        }
        armedPower = ""
        root.dashboardVisible = false
        Quickshell.execDetached(action.cmd)
    }

    Timer { id: disarmTimer; interval: 3000; onTriggered: dashboard.armedPower = "" }

    Connections {
        target: root
        function onDashboardVisibleChanged() {
            if (!root.dashboardVisible) {
                dashboard.armedPower = ""
                profileSection.pfpPickerOpen = false
            }
        }
    }

    SystemClock { id: sysClock; precision: SystemClock.Seconds }

    // Takes the keyboard while the panel holds focus (see the grab in shell.qml).
    Item {
        focus: true
        Keys.onEscapePressed: root.dashboardVisible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.7)
        radius: 20

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Card {
                id: profileSection
                Layout.fillWidth: true
                Layout.preferredHeight: pfpPickerOpen ? 280 : 100
                radius: 15
                clip: true
                property bool pfpPickerOpen: false
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15
                        Item {
                            id: pfpContainer
                            width: 74
                            height: 74
                            Rectangle {
                                id: pfpBorder
                                anchors.fill: parent
                                radius: 37
                                color: "transparent"
                                border.width: 3
                                border.color: Theme.color5
                            }
                            ClippingRectangle {
                                anchors.centerIn: parent
                                width: 68
                                height: 68
                                radius: 34
                                color: "transparent"
                                Image {
                                    id: pfpImage
                                    anchors.fill: parent
                                    // Falls back to the bundled default if the picked file is gone.
                                    property bool failed: false
                                    source: "file://" + (failed ? dashboard.defaultAvatar : dashboard.avatarPath)
                                    onStatusChanged: if (status === Image.Error) failed = true
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    sourceSize.width: 256
                                    sourceSize.height: 256
                                }
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                width: 22
                                height: 22
                                radius: 11
                                color: Theme.color5
                                border.width: 2
                                border.color: Theme.background
                                StyledText {
                                    anchors.centerIn: parent
                                    text: "󰏫"
                                    color: Theme.background
                                    font.pixelSize: 12
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    profileSection.pfpPickerOpen = !profileSection.pfpPickerOpen
                                    if (profileSection.pfpPickerOpen) pfpListProc.running = true
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            StyledText {
                                text: Quickshell.env("USER")
                                color: Theme.color5
                                font.pixelSize: 26
                                font.bold: true
                            }
                            StyledText {
                                text: dashboard.uptimeText
                                color: Theme.foreground
                                font.pixelSize: 12
                            }
                        }
                    }
                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        visible: profileSection.pfpPickerOpen
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            StyledText {
                                text: "Choose Avatar"
                                color: Theme.color5
                                font.pixelSize: 12
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: width
                                contentHeight: pfpGrid.height
                                clip: true
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                GridLayout {
                                    id: pfpGrid
                                    width: parent.width
                                    columns: 6
                                    rowSpacing: 8
                                    columnSpacing: 8
                                    Repeater {
                                        model: dashboard.pfpFiles
                                        Item {
                                            width: 48
                                            height: 48
                                            Layout.alignment: Qt.AlignHCenter
                                            readonly property bool isCurrent: modelData === dashboard.avatarPath
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 24
                                                color: "transparent"
                                                border.width: 2
                                                border.color: parent.isCurrent ? Theme.color2
                                                    : thumbMa.containsMouse ? Theme.color13 : Theme.color5
                                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                            }
                                            ClippingRectangle {
                                                anchors.centerIn: parent
                                                width: 44
                                                height: 44
                                                radius: 22
                                                color: "transparent"
                                                Image {
                                                    anchors.fill: parent
                                                    source: "file://" + modelData
                                                    fillMode: Image.PreserveAspectCrop
                                                    smooth: true
                                                    asynchronous: true
                                                    sourceSize.width: 128
                                                    sourceSize.height: 128
                                                }
                                            }
                                            MouseArea {
                                                id: thumbMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Settings.avatar = modelData
                                                    pfpImage.failed = false
                                                    profileSection.pfpPickerOpen = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Process {
                    id: pfpListProc
                    command: ["find", Paths.assets + "/pfps", "-maxdepth", "1", "-type", "f",
                              "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png",
                              "-o", "-iname", "*.gif", "-o", "-iname", "*.webp", ")", "!", "-name", "pfp.jpg"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var files = text.split("\n").filter(function(f) { return f !== "" })
                            files.sort(function(a, b) { return a.localeCompare(b) })
                            dashboard.pfpFiles = files
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: dashboard.armedPower !== "" ? 72 : 50
                radius: 15
                clip: true
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 25
                        Repeater {
                            // Log out: Hyprland's Lua config (0.56+) only accepts Lua dispatchers.
                            model: [
                                { label: "Power off", icon: "⏻", color: Theme.color2, cmd: ["systemctl", "poweroff"], confirm: true },
                                { label: "Reboot", icon: "󰜉", color: Theme.color13, cmd: ["systemctl", "reboot"], confirm: true },
                                { label: "Lock", icon: "󰌾", color: Theme.color5, cmd: ["hyprlock"], confirm: false },
                                { label: "Suspend", icon: "󰒲", color: Theme.color4, cmd: ["systemctl", "suspend"], confirm: false },
                                { label: "Log out", icon: "󰍃", color: Theme.color1, cmd: ["hyprctl", "dispatch", Hyprland.usingLua ? "hl.dsp.exit()" : "exit"], confirm: true }
                            ]
                            PowerBtn {
                                icon: modelData.icon
                                iconColor: modelData.color
                                armed: dashboard.armedPower === modelData.label
                                onActivated: dashboard.runPower(modelData)
                            }
                        }
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: dashboard.armedPower !== ""
                        text: "Click again to " + dashboard.armedPower.toLowerCase()
                        color: Theme.color8
                        font.pixelSize: 11
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: 15
                visible: Battery.present
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    StyledText {
                        id: batIcon
                        text: Battery.glyph
                        color: Battery.low ? Theme.color1 : Theme.color2
                        font.pixelSize: 32
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        StyledText {
                            text: "Battery " + Battery.percent + "%"
                            color: Theme.foreground
                            font.pixelSize: 18
                        }
                        StyledText {
                            id: batStatus
                            Layout.fillWidth: true
                            text: Battery.statusText
                            color: Battery.low ? Theme.color1 : Theme.color8
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                radius: 15
                Row {
                    anchors.centerIn: parent
                    spacing: 30
                    CircularStat { label: "CPU"; icon: "󰻠"; barColor: Theme.color1; value: dashboard.cpuVal }
                    CircularStat { label: "RAM"; icon: "󰍛"; barColor: Theme.color5; value: dashboard.ramVal }
                    CircularStat { label: "DISK"; icon: "󰋊"; barColor: Theme.color4; value: dashboard.diskVal }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                radius: 15
                Column {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    ValueSlider {
                        icon: Audio.glyph
                        barColor: Theme.color4
                        value: Audio.volume
                        muted: Audio.muted
                        iconInteractive: true
                        onIconClicked: Audio.toggleMute()
                        onMoved: percent => Audio.setVolume(percent)
                    }
                    ValueSlider {
                        icon: dashboard.brightVal < 30 ? "󰃞" : dashboard.brightVal < 70 ? "󰃟" : "󰃠"
                        barColor: Theme.color13
                        value: dashboard.brightVal
                        minValue: 1
                        onMoved: percent => {
                            dashboard.brightVal = percent
                            brightSetProc.request(percent)
                        }
                    }
                }
            }

            // Keep awake: an idle inhibitor on the bar (only matters while an
            // idle daemon such as hypridle is running).
            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 15
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 12
                    StyledText {
                        text: "󰅶"
                        color: root.keepAwake ? Theme.color3 : Theme.color8
                        font.pixelSize: 18
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        StyledText {
                            text: "Keep awake"
                            color: Theme.foreground
                            font.pixelSize: 13
                        }
                        StyledText {
                            text: root.keepAwake ? "Idle lock and sleep are paused" : "Idle lock and sleep as usual"
                            color: Theme.color8
                            font.pixelSize: 10
                        }
                    }
                    ToggleSwitch {
                        checked: root.keepAwake
                        onToggled: root.keepAwake = !root.keepAwake
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 15
                Column {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    StyledText {
                        id: timeDisplay
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(sysClock.date, "hh:mm:ss AP")
                        color: Theme.color5
                        font.pixelSize: 40
                    }
                    StyledText {
                        id: dateDisplay
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(sysClock.date, "dd.MM.yyyy, dddd")
                        color: Theme.foreground
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    component CircularStat: Item {
        id: stat
        property string label
        property string icon
        property color barColor
        property int value
        // Repaint on theme changes too, not just new values.
        onValueChanged: ring.requestPaint()
        onBarColorChanged: ring.requestPaint()
        width: 90
        height: 110
        Column {
            anchors.centerIn: parent
            spacing: 8
            Item {
                width: 70
                height: 70
                anchors.horizontalCenter: parent.horizontalCenter
                Canvas {
                    id: ring
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.lineWidth = 5
                        ctx.lineCap = "round"
                        ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.3)
                        ctx.beginPath()
                        ctx.arc(35, 35, 32, 0, 2 * Math.PI)
                        ctx.stroke()
                        ctx.strokeStyle = stat.barColor
                        ctx.beginPath()
                        ctx.arc(35, 35, 32, -Math.PI / 2, -Math.PI / 2 + (stat.value / 100) * 2 * Math.PI)
                        ctx.stroke()
                    }
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: stat.icon
                        color: stat.barColor
                        font.pixelSize: 16
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: stat.value + "%"
                        color: Theme.foreground
                        font.pixelSize: 14
                    }
                }
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: stat.label
                color: Theme.color8
                font.pixelSize: 11
            }
        }
    }

    component PowerBtn: Rectangle {
        id: powerBtn
        property string icon
        property color iconColor
        property bool armed: false
        signal activated()
        width: 40
        height: 40
        radius: 10
        color: armed ? Theme.alpha(iconColor, 0.25) : powerMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
        border.width: armed ? 1 : 0
        border.color: iconColor
        Behavior on color { ColorAnimation { duration: 150 } }
        StyledText {
            anchors.centerIn: parent
            text: powerBtn.icon
            color: powerBtn.iconColor
            font.pixelSize: 18
        }
        MouseArea {
            id: powerMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: powerBtn.activated()
        }
    }

    // Remaining polled stats (cpu/ram/disk/brightness/uptime) — only while the
    // dashboard is visible. CPU, RAM and uptime are plain /proc reads (no
    // processes); battery + volume are event-driven (Battery/Audio singletons) and the
    // clock is a SystemClock. triggeredOnStart refreshes the moment it opens.
    Timer {
        interval: 2000
        running: root.dashboardVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            meminfoFile.reload()
            uptimeFile.reload()
            diskProc.running = true
            // Don't let a poll yank the slider back mid-drag.
            if (!brightSetProc.running) brightProc.running = true
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: dashboard.uptimeText = dashboard.formatUptime(parseFloat(text().split(" ")[0]))
    }

    // CPU% from /proc/stat jiffy deltas.
    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            var f = text().split("\n", 1)[0].trim().split(/\s+/)  // ["cpu", user, nice, system, idle, iowait, ...]
            if (f.length < 5 || f[0] !== "cpu") return
            var total = 0
            for (var i = 1; i < f.length; i++) total += parseInt(f[i]) || 0
            var idle = (parseInt(f[4]) || 0) + (parseInt(f[5]) || 0)  // idle + iowait
            var dTotal = total - dashboard.cpuPrevTotal
            var dIdle = idle - dashboard.cpuPrevIdle
            if (dashboard.cpuPrevTotal > 0 && dTotal > 0)
                dashboard.cpuVal = Math.round(100 * (dTotal - dIdle) / dTotal)
            dashboard.cpuPrevTotal = total
            dashboard.cpuPrevIdle = idle
        }
    }

    // RAM% as (MemTotal - MemAvailable) / MemTotal, i.e. what apps can't reclaim.
    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoaded: {
            var t = text()
            var total = t.match(/MemTotal:\s+(\d+)/)
            var avail = t.match(/MemAvailable:\s+(\d+)/)
            if (total && avail && parseInt(total[1]) > 0)
                dashboard.ramVal = Math.round(100 * (1 - parseInt(avail[1]) / parseInt(total[1])))
        }
    }

    Process {
        id: diskProc
        command: ["df", "--output=pcent", "/"]
        stdout: StdioCollector {
            onStreamFinished: dashboard.diskVal = parseInt(text.split("\n")[1]) || 0
        }
    }
    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]  // name,class,current,percent%,max
        stdout: SplitParser {
            // Not `|| 100`: 0% is a real (falsy) reading.
            onRead: data => {
                var percent = parseInt(data.split(",")[3])
                if (!isNaN(percent)) dashboard.brightVal = percent
            }
        }
    }
    Process {
        id: brightSetProc
        property int target: -1
        property int sent: -1
        command: ["brightnessctl", "-q", "set", target + "%"]
        function request(percent) {
            target = percent
            if (!running) { sent = target; running = true }
        }
        // A drag fires faster than brightnessctl exits, and `running = true`
        // is a no-op mid-run, so re-run until the latest value has been applied.
        onExited: if (sent !== target) { sent = target; running = true }
    }
}
