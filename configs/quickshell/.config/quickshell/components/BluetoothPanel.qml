import Quickshell
import "../Common"
import Quickshell.Bluetooth
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: btPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 40; right: root.btVisible ? 6 : -350 }
    implicitHeight: 460
    implicitWidth: 320
    color: "transparent"
    WlrLayershell.keyboardFocus: root.btVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Self-contained Bluetooth state from Quickshell.Bluetooth.
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: adapter !== null && adapter.enabled
    readonly property var allDevices: adapter ? adapter.devices.values : []
    readonly property var pairedDevices: {
        var out = []
        for (var i = 0; i < allDevices.length; i++)
            if (allDevices[i].paired) out.push(allDevices[i])
        return out
    }
    readonly property var availableDevices: {
        var out = []
        for (var i = 0; i < allDevices.length; i++) {
            var d = allDevices[i]
            if (!d.paired && (d.deviceName || d.name)) out.push(d)
        }
        return out
    }
    readonly property bool btScanning: adapter !== null && adapter.discovering
    // Device we asked to pair; once BlueZ reports it paired, trust and connect
    // it so a new headset is usable in one click.
    property var pairingDevice: null
    // Address of the paired device whose "forget" awaits a confirming click.
    property string armedForget: ""
    // BlueZ tracks discovery per client, and another one (e.g. blueman) may be
    // scanning; only stop discovery this panel started.
    property bool ownsDiscovery: false

    // Nerd-font glyph for a BlueZ device icon name (audio-headset, input-mouse, ...).
    function deviceGlyph(icon) {
        if (!icon) return "󰂯"
        if (icon.startsWith("audio-head")) return "󰋋"
        if (icon.startsWith("audio")) return "󰓃"
        if (icon === "input-mouse") return "󰍽"
        if (icon === "input-keyboard") return "󰌌"
        if (icon === "input-gaming") return "󰊴"
        if (icon === "phone") return "󰄜"
        if (icon === "computer") return "󰌢"
        return "󰂯"
    }

    function forget(device) {
        if (armedForget !== device.address) {
            armedForget = device.address
            disarmTimer.restart()
            return
        }
        armedForget = ""
        device.forget()
    }

    Timer { id: disarmTimer; interval: 3000; onTriggered: btPanel.armedForget = "" }

    Connections {
        target: btPanel.pairingDevice
        function onPairedChanged() {
            var d = btPanel.pairingDevice
            if (!d || !d.paired) return
            d.trusted = true
            d.connect()
            btPanel.pairingDevice = null
        }
    }

    // Stop discovery when the panel is dismissed.
    Connections {
        target: root
        function onBtVisibleChanged() {
            if (!root.btVisible) {
                if (btPanel.adapter && btPanel.ownsDiscovery) btPanel.adapter.discovering = false
                btPanel.ownsDiscovery = false
                btPanel.armedForget = ""
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.7)
        radius: 20

        // Takes the keyboard while the panel holds focus (see the grab in shell.qml).
        Item {
            focus: true
            Keys.onEscapePressed: root.btVisible = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "󰂯"
                    color: Theme.color5
                    font.pixelSize: 22
                }
                StyledText {
                    text: "Bluetooth"
                    color: Theme.color5
                    font.pixelSize: 16
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                ToggleSwitch {
                    checked: btPanel.btEnabled
                    onToggled: if (btPanel.adapter) btPanel.adapter.enabled = !btPanel.adapter.enabled
                }
            }

            StyledText {
                text: "Paired Devices"
                color: Theme.color8
                font.pixelSize: 11
                visible: btPanel.btEnabled
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 12
                clip: true
                visible: btPanel.btEnabled
                ListView {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: btPanel.pairedDevices
                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 48
                        radius: 10
                        color: btPairedMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        readonly property bool forgetArmed: btPanel.armedForget === modelData.address
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            StyledText {
                                text: btPanel.deviceGlyph(modelData.icon)
                                color: modelData.connected ? Theme.color2 : Theme.color8
                                font.pixelSize: 18
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                StyledText {
                                    text: modelData.deviceName || modelData.name || modelData.address
                                    color: modelData.connected ? Theme.color2 : Theme.foreground
                                    font.pixelSize: 12
                                    font.bold: modelData.connected
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: {
                                        if (forgetArmed) return "Click 󰆴 again to forget"
                                        if (modelData.state === BluetoothDeviceState.Connecting) return "Connecting..."
                                        if (modelData.connected)
                                            return "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                                        return "Paired"
                                    }
                                    color: forgetArmed ? Theme.color1 : Theme.color8
                                    font.pixelSize: 9
                                }
                            }
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 8
                                color: btConnBtnMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "󰅖" : "󰐕"
                                    color: modelData.connected ? Theme.color1 : Theme.color5
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: btConnBtnMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                                }
                            }
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 8
                                color: forgetArmed ? Theme.alpha(Theme.color1, 0.25)
                                    : btForgetMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                                StyledText {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    color: forgetArmed ? Theme.color1 : Theme.color8
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: btForgetMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: btPanel.forget(modelData)
                                }
                            }
                        }
                        MouseArea {
                            id: btPairedMa
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                        }
                    }
                    ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: btPanel.pairedDevices.length === 0
                    text: "No paired devices"
                    color: Theme.color8
                    font.pixelSize: 12
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: btPanel.btEnabled
                StyledText {
                    text: "Available Devices"
                    color: Theme.color8
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 60
                    height: 24
                    radius: 6
                    color: btScanBtnMa.containsMouse ? Theme.alpha(Theme.color5, 0.2) : Qt.rgba(0, 0, 0, 0.3)
                    StyledText {
                        anchors.centerIn: parent
                        text: btPanel.btScanning ? "Scanning" : "Scan"
                        color: Theme.color5
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: btScanBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!btPanel.adapter) return
                            var start = !btPanel.adapter.discovering
                            btPanel.adapter.discovering = start
                            btPanel.ownsDiscovery = start
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                clip: true
                visible: btPanel.btEnabled
                ListView {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: btPanel.availableDevices
                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 44
                        radius: 10
                        color: btAvailMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            StyledText {
                                text: btPanel.deviceGlyph(modelData.icon)
                                color: Theme.color8
                                font.pixelSize: 16
                            }
                            StyledText {
                                text: modelData.deviceName || modelData.name || modelData.address
                                color: Theme.foreground
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                visible: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
                                text: "..."
                                color: Theme.color8
                                font.pixelSize: 12
                            }
                        }
                        MouseArea {
                            id: btAvailMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btPanel.pairingDevice = modelData
                                modelData.pair()
                            }
                        }
                    }
                    ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: btPanel.availableDevices.length === 0 && !btPanel.btScanning
                    text: "Press Scan to find devices"
                    color: Theme.color8
                    font.pixelSize: 11
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: btPanel.btScanning && btPanel.availableDevices.length === 0
                    text: "Scanning..."
                    color: Theme.color8
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !btPanel.btEnabled
                color: "transparent"
                StyledText {
                    anchors.centerIn: parent
                    text: "Bluetooth is off"
                    color: Theme.color8
                    font.pixelSize: 13
                }
            }
        }
    }
}
