import Quickshell
import "../Common"
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: wifiPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 40; right: root.wifiVisible ? 6 : -350 }
    height: 420
    implicitWidth: 320
    color: "transparent"
    Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Self-contained Wi-Fi state from Quickshell.Networking.
    readonly property var wifiDev: {
        var devs = Networking.devices.values
        for (var i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i]
        return null
    }
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var allNetworks: (wifiEnabled && wifiDev && wifiDev.networks) ? wifiDev.networks.values : []
    readonly property var currentNetwork: {
        for (var i = 0; i < allNetworks.length; i++)
            if (allNetworks[i].connected) return allNetworks[i]
        return null
    }
    readonly property string wifiCurrentSSID: currentNetwork ? currentNetwork.name : ""
    readonly property int wifiSignal: currentNetwork ? Math.round(currentNetwork.signalStrength * 100) : 0
    // Display list: skip the connected one, dedup by SSID, sort by signal.
    readonly property var wifiNetworks: {
        var seen = ({}); var out = []
        for (var i = 0; i < allNetworks.length; i++) {
            var n = allNetworks[i]
            if (!n.name || n.name === "" || n.connected) continue
            if (seen[n.name]) continue
            seen[n.name] = true
            out.push({ ssid: n.name, signal: Math.round(n.signalStrength * 100),
                       secured: n.security !== WifiSecurityType.Open, net: n })
        }
        out.sort(function(a, b) { return b.signal - a.signal })
        return out
    }
    readonly property bool wifiScanning: wifiDev !== null && wifiDev.scannerEnabled === true && wifiNetworks.length === 0
    property string wifiPasswordSSID: ""
    property var pendingNetwork: null

    // Scan only while the panel is open. Managed imperatively (rather than via a
    // Binding) so the refresh button can toggle the scanner without a binding
    // fighting it back.
    function syncScanner() {
        if (wifiDev) wifiDev.scannerEnabled = root.wifiVisible
    }
    onWifiDevChanged: syncScanner()
    Connections {
        target: root
        function onWifiVisibleChanged() { wifiPanel.syncScanner() }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.7)
        radius: 20

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "󰤨"
                    color: Theme.color5
                    font.pixelSize: 22
                }
                StyledText {
                    text: "Wi-Fi"
                    color: Theme.color5
                    font.pixelSize: 16
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                ToggleSwitch {
                    checked: wifiPanel.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 12
                visible: wifiPanel.wifiCurrentSSID !== ""
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10
                    StyledText {
                        text: wifiPanel.wifiSignal > 66 ? "󰤨" : wifiPanel.wifiSignal > 33 ? "󰤥" : "󰤟"
                        color: Theme.color2
                        font.pixelSize: 18
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            text: wifiPanel.wifiCurrentSSID
                            color: Theme.color2
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: "Connected · " + wifiPanel.wifiSignal + "%"
                            color: Theme.color8
                            font.pixelSize: 10
                        }
                    }
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: wifiDiscMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                        StyledText {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: Theme.color1
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: wifiDiscMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (wifiPanel.wifiDev) wifiPanel.wifiDev.disconnect()
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 10
                visible: wifiPanel.wifiPasswordSSID !== ""
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    StyledText {
                        text: "󰌾"
                        color: Theme.color8
                        font.pixelSize: 12
                    }
                    TextInput {
                        id: wifiPassInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        clip: true
                        Text {
                            text: "Password for " + wifiPanel.wifiPasswordSSID
                            color: Theme.color8
                            visible: !parent.text
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            font: parent.font
                        }
                        Keys.onReturnPressed: {
                            if (wifiPassInput.text.length > 0 && wifiPanel.pendingNetwork) {
                                wifiPanel.pendingNetwork.connectWithPsk(wifiPassInput.text)
                                wifiPanel.wifiPasswordSSID = ""
                                wifiPanel.pendingNetwork = null
                                wifiPassInput.text = ""
                            }
                        }
                        Keys.onEscapePressed: {
                            wifiPanel.wifiPasswordSSID = ""
                            wifiPanel.pendingNetwork = null
                            wifiPassInput.text = ""
                        }
                    }
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 6
                        color: Theme.color5
                        StyledText {
                            anchors.centerIn: parent
                            text: "→"
                            color: Theme.background
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (wifiPassInput.text.length > 0 && wifiPanel.pendingNetwork) {
                                    wifiPanel.pendingNetwork.connectWithPsk(wifiPassInput.text)
                                    wifiPanel.wifiPasswordSSID = ""
                                    wifiPanel.pendingNetwork = null
                                    wifiPassInput.text = ""
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: wifiPanel.wifiEnabled
                StyledText {
                    text: "Available Networks"
                    color: Theme.color8
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: wifiRefreshMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: wifiPanel.wifiScanning ? "󰑓" : "󰑐"
                        color: Theme.color8
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: wifiRefreshMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Toggle the scanner off/on to force a fresh scan.
                        onClicked: {
                            if (wifiPanel.wifiDev) {
                                wifiPanel.wifiDev.scannerEnabled = false
                                wifiPanel.wifiDev.scannerEnabled = true
                            }
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                clip: true
                ListView {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: wifiPanel.wifiNetworks
                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 44
                        radius: 10
                        color: wifiNetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            StyledText {
                                text: modelData.signal > 66 ? "󰤨" : modelData.signal > 33 ? "󰤥" : "󰤟"
                                color: Theme.color5
                                font.pixelSize: 16
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                StyledText {
                                    text: modelData.ssid
                                    color: Theme.foreground
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: (modelData.secured ? "󰌾 Secured" : "Open") + " · " + modelData.signal + "%"
                                    color: Theme.color8
                                    font.pixelSize: 9
                                }
                            }
                        }
                        MouseArea {
                            id: wifiNetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Known/open networks connect directly; unknown secured
                                // ones prompt for a passphrase.
                                if (modelData.secured && !modelData.net.known) {
                                    wifiPanel.wifiPasswordSSID = modelData.ssid
                                    wifiPanel.pendingNetwork = modelData.net
                                    wifiPassInput.forceActiveFocus()
                                } else {
                                    modelData.net.connect()
                                }
                            }
                        }
                    }
                    ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: wifiPanel.wifiNetworks.length === 0 && !wifiPanel.wifiScanning
                    text: wifiPanel.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                    color: Theme.color8
                    font.pixelSize: 12
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: wifiPanel.wifiScanning
                    text: "Scanning..."
                    color: Theme.color8
                    font.pixelSize: 12
                }
            }
        }
    }
}