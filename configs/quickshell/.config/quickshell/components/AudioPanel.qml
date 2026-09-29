import Quickshell
import "../Common"
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Audio mixer: choose the output device and set per-app volumes. Opened by
// right-clicking the bar's volume pill (or `qs ipc call audio toggle`).
PanelWindow {
    id: audioPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 40; right: root.audioVisible ? 6 : -350 }
    implicitWidth: 320
    implicitHeight: 460
    color: "transparent"
    WlrLayershell.keyboardFocus: root.audioVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    readonly property var sinks: nodesOfType(PwNodeType.AudioSink)
    // App playback streams only exist while the app is actually playing.
    readonly property var streams: nodesOfType(PwNodeType.AudioOutStream)
    readonly property int defaultSinkId: Audio.sink ? Audio.sink.id : -1

    function nodesOfType(type) {
        var all = Pipewire.nodes.values
        var out = []
        for (var i = 0; i < all.length; i++) if (all[i].type === type) out.push(all[i])
        return out
    }

    function appName(node) {
        var p = node.properties || {}
        return p["application.name"] || node.description || node.name
    }

    function appIcon(node) {
        var p = node.properties || {}
        var icon = p["application.icon-name"] || p["application.process.binary"] || ""
        return icon ? Quickshell.iconPath(icon, true) : ""
    }

    // Bind the nodes (live volume/mute) only while the panel is open.
    PwObjectTracker { objects: root.audioVisible ? audioPanel.sinks.concat(audioPanel.streams) : [] }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.7)
        radius: 20

        // Takes the keyboard while the panel holds focus (see the grab in shell.qml).
        Item {
            focus: true
            Keys.onEscapePressed: root.audioVisible = false
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: Audio.glyph
                    color: Theme.color5
                    font.pixelSize: 22
                }
                StyledText {
                    text: "Audio"
                    color: Theme.color5
                    font.pixelSize: 16
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                // On = sound on, i.e. the inverse of muted.
                ToggleSwitch {
                    checked: Audio.ready && !Audio.muted
                    onToggled: Audio.toggleMute()
                }
            }

            ValueSlider {
                Layout.fillWidth: true
                icon: Audio.glyph
                barColor: Theme.color4
                value: Audio.volume
                muted: Audio.muted
                iconInteractive: true
                onIconClicked: Audio.toggleMute()
                onMoved: percent => Audio.setVolume(percent)
            }

            StyledText {
                text: "Output"
                color: Theme.color8
                font.pixelSize: 11
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(1, Math.min(audioPanel.sinks.length, 3)) * 44 + 8
                radius: 12
                clip: true
                ListView {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: audioPanel.sinks
                    delegate: Rectangle {
                        id: sinkRow
                        required property var modelData
                        readonly property bool isDefault: modelData.id === audioPanel.defaultSinkId
                        width: ListView.view.width
                        height: 40
                        radius: 10
                        color: isDefault ? Theme.alpha(Theme.color5, 0.15)
                            : sinkMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            StyledText {
                                // Bluetooth sinks are named "bluez_output.<address>...".
                                text: sinkRow.modelData.name.startsWith("bluez") ? "󰋋" : "󰓃"
                                color: sinkRow.isDefault ? Theme.color2 : Theme.color8
                                font.pixelSize: 16
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: sinkRow.modelData.description || sinkRow.modelData.nickname || sinkRow.modelData.name
                                color: sinkRow.isDefault ? Theme.color2 : Theme.foreground
                                font.pixelSize: 12
                                font.bold: sinkRow.isDefault
                                elide: Text.ElideRight
                            }
                            StyledText {
                                visible: sinkRow.isDefault
                                text: "󰄬"
                                color: Theme.color2
                                font.pixelSize: 13
                            }
                        }
                        MouseArea {
                            id: sinkMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                        }
                    }
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: audioPanel.sinks.length === 0
                    text: "No output devices"
                    color: Theme.color8
                    font.pixelSize: 12
                }
            }

            StyledText {
                text: "Applications"
                color: Theme.color8
                font.pixelSize: 11
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                clip: true
                ListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: audioPanel.streams
                    delegate: Column {
                        id: streamRow
                        required property var modelData
                        readonly property bool live: modelData.ready && modelData.audio !== null
                        readonly property string mediaName: (modelData.properties || {})["media.name"] || ""
                        width: ListView.view.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            spacing: 8
                            Item {
                                width: 16
                                height: 16
                                Image {
                                    id: streamIcon
                                    anchors.fill: parent
                                    source: audioPanel.appIcon(streamRow.modelData)
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    asynchronous: true
                                }
                                StyledText {
                                    anchors.centerIn: parent
                                    visible: streamIcon.status !== Image.Ready
                                    text: "󰝚"
                                    color: Theme.color5
                                    font.pixelSize: 13
                                }
                            }
                            StyledText {
                                text: audioPanel.appName(streamRow.modelData)
                                color: Theme.foreground
                                font.pixelSize: 12
                                font.bold: true
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: streamRow.mediaName !== ""
                                text: streamRow.mediaName
                                color: Theme.color8
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                        ValueSlider {
                            width: parent.width
                            enabled: streamRow.live
                            icon: streamRow.live && streamRow.modelData.audio.muted ? "󰝟" : "󰕾"
                            barColor: Theme.color13
                            value: streamRow.live ? Math.round(streamRow.modelData.audio.volume * 100) : 0
                            muted: streamRow.live && streamRow.modelData.audio.muted
                            iconInteractive: true
                            onIconClicked: if (streamRow.live) streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted
                            onMoved: percent => { if (streamRow.live) streamRow.modelData.audio.volume = percent / 100 }
                        }
                    }
                    ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                }
                Column {
                    anchors.centerIn: parent
                    visible: audioPanel.streams.length === 0
                    spacing: 4
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No apps are playing audio"
                        color: Theme.color8
                        font.pixelSize: 12
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Apps show up here while they play"
                        color: Theme.color8
                        font.pixelSize: 10
                        opacity: 0.7
                    }
                }
            }
        }
    }
}
