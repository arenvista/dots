import Quickshell
import "../Common"
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: wifiPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 40; right: root.wifiVisible ? 6 : -350 }
    implicitHeight: 420
    implicitWidth: 320
    color: "transparent"
    // Layer surfaces get no keyboard input by default. On demand while open:
    // the focus grab (shell.qml) then hands this panel the keyboard, so the
    // password field can be typed into and Escape closes. Not Exclusive,
    // which would make Hyprland drop the grab and close the panel.
    WlrLayershell.keyboardFocus: root.wifiVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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
    // Network of the last connect attempt, watched for connectionFailed.
    property var lastAttempt: null
    property string errorText: ""
    // SSID whose "forget" awaits a confirming second click.
    property string armedForget: ""

    function forget(net) {
        if (armedForget !== net.name) {
            armedForget = net.name
            forgetDisarm.restart()
            return
        }
        armedForget = ""
        net.forget()
    }

    Timer { id: forgetDisarm; interval: 3000; onTriggered: wifiPanel.armedForget = "" }

    // Scan only while the panel is open. Managed imperatively (rather than via a
    // Binding) so the refresh button can toggle the scanner without a binding
    // fighting it back.
    function syncScanner() {
        if (wifiDev) wifiDev.scannerEnabled = root.wifiVisible
    }
    onWifiDevChanged: syncScanner()
    Connections {
        target: root
        function onWifiVisibleChanged() {
            wifiPanel.syncScanner()
            // Never keep the exclusive keyboard grab on a hidden panel.
            if (!root.wifiVisible) {
                wifiPanel.cancelPassword()
                wifiPanel.errorText = ""
                wifiPanel.armedForget = ""
            }
        }
    }

    // Known/open networks connect directly; unknown secured ones prompt for a passphrase.
    function connectTo(entry) {
        errorText = ""
        if (entry.secured && !entry.net.known) {
            promptPassword(entry.net)
        } else {
            lastAttempt = entry.net
            entry.net.connect()
        }
    }

    function promptPassword(net) {
        wifiPasswordSSID = net.name
        pendingNetwork = net
        wifiPassInput.text = ""
        wifiPassInput.forceActiveFocus()
    }

    function submitPassword() {
        if (wifiPassInput.text.length === 0 || !pendingNetwork) return
        lastAttempt = pendingNetwork
        pendingNetwork.connectWithPsk(wifiPassInput.text)
        cancelPassword()
    }

    function cancelPassword() {
        wifiPasswordSSID = ""
        pendingNetwork = null
        wifiPassInput.text = ""
        keyCatcher.forceActiveFocus()
    }

    function failReason(reason) {
        if (reason === ConnectionFailReason.NoSecrets) return "wrong password?"
        if (reason === ConnectionFailReason.WifiAuthTimeout) return "authentication timed out"
        if (reason === ConnectionFailReason.WifiNetworkLost) return "network lost"
        return ConnectionFailReason.toString(reason)
    }

    Connections {
        target: wifiPanel.lastAttempt
        function onConnectionFailed(reason) {
            var net = wifiPanel.lastAttempt
            wifiPanel.errorText = "Couldn't join " + net.name + ": " + wifiPanel.failReason(reason)
            // Missing/wrong secrets: ask again rather than leaving a dead end.
            if (reason === ConnectionFailReason.NoSecrets && root.wifiVisible)
                wifiPanel.promptPassword(net)
        }
        function onConnectedChanged() {
            if (wifiPanel.lastAttempt && wifiPanel.lastAttempt.connected) {
                wifiPanel.errorText = ""
                wifiPanel.lastAttempt = null
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.7)
        radius: 20

        // Takes the keyboard while the panel holds focus (see the grab in shell.qml).
        Item {
            id: keyCatcher
            focus: true
            Keys.onEscapePressed: root.wifiVisible = false
        }

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
                            readonly property bool armed: wifiPanel.armedForget !== "" && wifiPanel.armedForget === wifiPanel.wifiCurrentSSID
                            text: armed ? "Click 󰆴 again to forget" : "Connected · " + wifiPanel.wifiSignal + "%"
                            color: armed ? Theme.color1 : Theme.color8
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
                    ForgetButton {
                        armed: wifiPanel.armedForget !== "" && wifiPanel.armedForget === wifiPanel.wifiCurrentSSID
                        onClicked: if (wifiPanel.currentNetwork) wifiPanel.forget(wifiPanel.currentNetwork)
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 10
                visible: wifiPanel.wifiPasswordSSID !== ""
                border.width: wifiPassInput.activeFocus ? 1 : 0
                border.color: Theme.color5
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
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Keys.onReturnPressed: wifiPanel.submitPassword()
                        Keys.onEnterPressed: wifiPanel.submitPassword()
                        Keys.onEscapePressed: wifiPanel.cancelPassword()
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
                            onClicked: wifiPanel.submitPassword()
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: wifiPanel.errorText !== ""
                text: "󰀦 " + wifiPanel.errorText
                color: Theme.color1
                font.pixelSize: 10
                wrapMode: Text.Wrap
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
                                    text: {
                                        if (wifiPanel.armedForget === modelData.ssid) return "Click 󰆴 again to forget"
                                        if (modelData.net.state === ConnectionState.Connecting) return "Connecting..."
                                        return (modelData.secured ? "󰌾 Secured" : "Open")
                                            + (modelData.net.known ? " · Saved" : "")
                                            + " · " + modelData.signal + "%"
                                    }
                                    color: wifiPanel.armedForget === modelData.ssid ? Theme.color1 : Theme.color8
                                    font.pixelSize: 9
                                }
                            }
                            ForgetButton {
                                visible: modelData.net.known
                                armed: wifiPanel.armedForget === modelData.ssid
                                onClicked: wifiPanel.forget(modelData.net)
                            }
                        }
                        MouseArea {
                            id: wifiNetMa
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifiPanel.connectTo(modelData)
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

    component ForgetButton: Rectangle {
        id: forgetBtn
        property bool armed: false
        signal clicked()
        width: 28
        height: 28
        radius: 8
        color: armed ? Theme.alpha(Theme.color1, 0.25) : forgetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
        StyledText {
            anchors.centerIn: parent
            text: "󰆴"
            color: forgetBtn.armed ? Theme.color1 : Theme.color8
            font.pixelSize: 12
        }
        MouseArea {
            id: forgetMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: forgetBtn.clicked()
        }
    }
}
