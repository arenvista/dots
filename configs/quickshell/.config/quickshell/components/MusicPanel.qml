import Quickshell
import "../Common"
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: musicPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true }
    margins { top: root.musicVisible ? 50 : -350; left: 0; right: 0 }
    implicitWidth: 400
    implicitHeight: musicPanel.gifSelectorOpen ? 460 : 188
    color: "transparent"
    Behavior on margins.top { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Active MPRIS player: prefer one that's playing, else the first available.
    readonly property var player: {
        var ps = Mpris.players.values
        if (ps.length === 0) return null
        for (var i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i]
        return ps[0]
    }
    readonly property string playerStatus: {
        if (!player) return "Stopped"
        if (player.playbackState === MprisPlaybackState.Playing) return "Playing"
        if (player.playbackState === MprisPlaybackState.Paused) return "Paused"
        return "Stopped"
    }
    readonly property string trackTitle: player ? player.trackTitle : ""
    readonly property string trackArtist: player ? player.trackArtist : ""
    property real position: 0
    readonly property real length: player ? player.length : 0
    readonly property bool hasTrack: playerStatus === "Playing" || playerStatus === "Paused"
    property var gifFiles: []
    property int currentGifIndex: 0
    property int previewGifIndex: 0
    property bool gifSelectorOpen: false
    property bool gifsLoaded: false
    property int gifReloadCounter: 0
    property bool isApplyingGif: false
    property string currentGifSource: Paths.fileUrl("assets/gifs/current.gif")
    property int pendingGifIndex: -1

    function formatTime(seconds) {
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function nextGif() {
        if (gifFiles.length > 0) {
            previewGifIndex = (previewGifIndex + 1) % gifFiles.length
        }
    }

    function prevGif() {
        if (gifFiles.length > 0) {
            previewGifIndex = (previewGifIndex - 1 + gifFiles.length) % gifFiles.length
        }
    }

    function applyGif() {
        if (isApplyingGif) return
        if (gifFiles.length > 0 && previewGifIndex < gifFiles.length) {
            isApplyingGif = true
            pendingGifIndex = previewGifIndex
            danceGifLoader.active = false
            setGifProc.selFile = gifFiles[previewGifIndex]
            setGifProc.running = true
        }
    }

    function loadGifs() {
        if (gifListProc.running) return
        musicPanel.gifFiles = []
        musicPanel.gifsLoaded = false
        musicPanel.previewGifIndex = 0
        gifListProc.running = true
    }

    function gifFileName(path) {
        var parts = path.split("/")
        var name = parts[parts.length - 1]
        return name.replace(".gif", "")
    }

    function reloadMainGif() {
        musicPanel.gifReloadCounter++
        musicPanel.currentGifSource = Paths.fileUrl("assets/gifs/current.gif") + "?v=" + musicPanel.gifReloadCounter + "&t=" + Date.now()
        danceGifLoader.active = true
        musicPanel.isApplyingGif = false
        musicPanel.pendingGifIndex = -1
    }

    onGifSelectorOpenChanged: {
        if (!gifSelectorOpen) {
            previewGifIndex = currentGifIndex
        }
    }

    Timer {
        id: gifReloadTimer
        interval: 250
        repeat: false
        onTriggered: musicPanel.reloadMainGif()
    }

    Item {
        anchors.fill: parent

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Rectangle {
                width: 400
                height: 180
                color: Theme.alpha(Theme.background, 0.7)
                radius: 15
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        StyledText {
                            text: musicPanel.trackTitle || "Nothing is playing"
                            color: Theme.color5
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: musicPanel.trackArtist || ""
                            color: Theme.foreground
                            font.pixelSize: 12
                            opacity: 0.7
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            visible: musicPanel.trackArtist !== ""
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: musicPanel.hasTrack

                            StyledText {
                                text: musicPanel.formatTime(musicPanel.position)
                                color: Theme.color8
                                font.pixelSize: 10
                            }

                            Card {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2

                                Rectangle {
                                    width: musicPanel.length > 0 ? parent.width * (musicPanel.position / musicPanel.length) : 0
                                    height: parent.height
                                    radius: 2
                                    color: Theme.color5
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (musicPanel.player && musicPanel.length > 0) {
                                            var seekPos = (mouse.x / parent.width) * musicPanel.length
                                            musicPanel.player.position = seekPos
                                            musicPanel.position = seekPos
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: musicPanel.formatTime(musicPanel.length)
                                color: Theme.color8
                                font.pixelSize: 10
                            }
                        }

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12
                            opacity: musicPanel.hasTrack ? 1.0 : 0.5

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "󰒮"
                                    color: Theme.foreground
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    id: prevMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (musicPanel.player) musicPanel.player.previous()
                                }
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.color5

                                StyledText {
                                    anchors.centerIn: parent
                                    text: musicPanel.playerStatus === "Playing" ? "󰏤" : "󰐊"
                                    color: Theme.background
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (musicPanel.player) musicPanel.player.togglePlaying()
                                }
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "󰒭"
                                    color: Theme.foreground
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    id: nextMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (musicPanel.player) musicPanel.player.next()
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 160
                        Layout.alignment: Qt.AlignBottom

                        Item {
                            id: gifContainer
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 200
                            height: 160

                            Loader {
                                id: danceGifLoader
                                anchors.fill: parent
                                active: true
                                sourceComponent: AnimatedImage {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    source: musicPanel.currentGifSource
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    playing: musicPanel.playerStatus === "Playing"
                                    paused: musicPanel.playerStatus !== "Playing"
                                    cache: false
                                    asynchronous: true
                                }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 5
                            anchors.rightMargin: 5
                            width: 24
                            height: 24
                            radius: 12
                            color: gifEditMa.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(0,0,0,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            StyledText {
                                anchors.centerIn: parent
                                text: "󰏫"
                                color: Theme.foreground
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: gifEditMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!musicPanel.gifSelectorOpen) {
                                        musicPanel.loadGifs()
                                        musicPanel.gifSelectorOpen = true
                                    } else {
                                        musicPanel.gifSelectorOpen = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: dropdownCard
                width: 380
                height: 260
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 14
                color: Theme.alpha(Theme.background, 0.75)
                border.color: Qt.rgba(1,1,1,0.1)
                border.width: 1
                visible: musicPanel.gifSelectorOpen
                clip: true

                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 16
                    samples: 17
                    color: Qt.rgba(0,0,0,0.35)
                }

                ColumnLayout {
                    id: dropdownContent
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20

                        StyledText {
                            text: "Select Animation"
                            color: Theme.color5
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        StyledText {
                            visible: musicPanel.gifFiles.length > 0
                            text: (musicPanel.previewGifIndex + 1) + " / " + musicPanel.gifFiles.length
                            color: Theme.color8
                            font.pixelSize: 10
                            opacity: 0.6
                        }

                        Item { width: 6 }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: dropCloseMa.containsMouse ? Theme.alpha(Theme.color1, 0.5) : Qt.rgba(1,1,1,0.08)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            StyledText {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: dropCloseMa.containsMouse ? Theme.color1 : Theme.foreground
                                font.pixelSize: 10
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: dropCloseMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: musicPanel.gifSelectorOpen = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(1,1,1,0.06)
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            id: previewContainer
                            anchors.fill: parent
                            radius: 12
                            color: Qt.rgba(0,0,0,0.2)
                            border.color: Qt.rgba(1,1,1,0.08)
                            border.width: 1
                            clip: true

                            Item {
                                id: previewPadding
                                anchors.fill: parent
                                anchors.margins: 12

                                Loader {
                                    id: previewGifLoader
                                    anchors.fill: parent
                                    active: musicPanel.gifSelectorOpen && musicPanel.gifsLoaded && musicPanel.gifFiles.length > 0
                                    sourceComponent: AnimatedImage {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                        source: (musicPanel.gifFiles.length > 0 && musicPanel.previewGifIndex < musicPanel.gifFiles.length) ? "file://" + musicPanel.gifFiles[musicPanel.previewGifIndex] : ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        playing: musicPanel.gifSelectorOpen
                                        cache: false
                                        asynchronous: true
                                    }
                                }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: musicPanel.gifFiles.length === 0 && musicPanel.gifsLoaded
                                text: "No gifs found"
                                color: Theme.color8
                                font.pixelSize: 11
                                opacity: 0.5
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: !musicPanel.gifsLoaded && musicPanel.gifSelectorOpen
                                text: "Loading..."
                                color: Theme.color8
                                font.pixelSize: 11
                                opacity: 0.5
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 8
                                visible: musicPanel.gifFiles.length > 0 && musicPanel.gifsLoaded
                                width: nameLabel.implicitWidth + 16
                                height: 20
                                radius: 10
                                color: Qt.rgba(0,0,0,0.6)

                                StyledText {
                                    id: nameLabel
                                    anchors.centerIn: parent
                                    text: (musicPanel.gifFiles.length > 0 && musicPanel.previewGifIndex < musicPanel.gifFiles.length) ? musicPanel.gifFileName(musicPanel.gifFiles[musicPanel.previewGifIndex]) : ""
                                    color: Theme.foreground
                                    font.pixelSize: 9
                                    opacity: 0.9
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 32
                            radius: 8
                            color: prevGifMa.containsMouse ? Theme.alpha(Theme.color5, 0.25) : Qt.rgba(1,1,1,0.08)
                            border.color: prevGifMa.containsMouse ? Theme.alpha(Theme.color5, 0.4) : Qt.rgba(1,1,1,0.05)
                            border.width: 1
                            opacity: musicPanel.gifFiles.length > 1 ? 1.0 : 0.3
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            StyledText {
                                anchors.centerIn: parent
                                text: "󰅁"
                                color: prevGifMa.containsMouse ? Theme.color5 : Theme.foreground
                                font.pixelSize: 16
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: prevGifMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: musicPanel.gifFiles.length > 1 && !musicPanel.isApplyingGif
                                onClicked: musicPanel.prevGif()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 32
                            radius: 8
                            color: nextGifMa.containsMouse ? Theme.alpha(Theme.color5, 0.25) : Qt.rgba(1,1,1,0.08)
                            border.color: nextGifMa.containsMouse ? Theme.alpha(Theme.color5, 0.4) : Qt.rgba(1,1,1,0.05)
                            border.width: 1
                            opacity: musicPanel.gifFiles.length > 1 ? 1.0 : 0.3
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            StyledText {
                                anchors.centerIn: parent
                                text: "󰅂"
                                color: nextGifMa.containsMouse ? Theme.color5 : Theme.foreground
                                font.pixelSize: 16
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: nextGifMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: musicPanel.gifFiles.length > 1 && !musicPanel.isApplyingGif
                                onClicked: musicPanel.nextGif()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 85
                            Layout.preferredHeight: 32
                            radius: 8
                            color: {
                                if (musicPanel.isApplyingGif) return Qt.rgba(1,1,1,0.03)
                                if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return Qt.rgba(1,1,1,0.05)
                                return applyGifMa.pressed ? Theme.color5 : applyGifMa.containsMouse ? Theme.alpha(Theme.color5, 0.35) : Theme.alpha(Theme.color5, 0.18)
                            }
                            border.color: {
                                if (musicPanel.isApplyingGif) return Qt.rgba(1,1,1,0.05)
                                if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return Qt.rgba(1,1,1,0.08)
                                return applyGifMa.containsMouse ? Theme.color5 : Theme.alpha(Theme.color5, 0.4)
                            }
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (musicPanel.isApplyingGif) return "Applying..."
                                    if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return "󰄬 Current"
                                    return "󰸞 Apply"
                                }
                                color: {
                                    if (musicPanel.isApplyingGif) return Theme.alpha(Theme.foreground, 0.4)
                                    if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return Theme.alpha(Theme.foreground, 0.3)
                                    return applyGifMa.pressed ? Theme.background : Theme.color5
                                }
                                font.pixelSize: 11
                                font.bold: true
                                font.family: Theme.fontFamily
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: applyGifMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: (musicPanel.previewGifIndex !== musicPanel.currentGifIndex && !musicPanel.isApplyingGif) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: musicPanel.previewGifIndex !== musicPanel.currentGifIndex && !musicPanel.isApplyingGif
                                onClicked: musicPanel.applyGif()
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: gifListProc
        command: ["sh", "-c", "find \"$1/gifs\" -maxdepth 1 -name '*.gif' ! -name 'current.gif' -type f 2>/dev/null | sort", "_", Paths.assets]
        stdout: SplitParser {
            onRead: data => {
                var file = data.trim()
                if (file.length > 0) {
                    var current = musicPanel.gifFiles.slice()
                    current.push(file)
                    musicPanel.gifFiles = current
                }
            }
        }
        onExited: {
            musicPanel.gifsLoaded = true
            if (musicPanel.gifFiles.length > 0) {
                musicPanel.previewGifIndex = Math.min(musicPanel.currentGifIndex, musicPanel.gifFiles.length - 1)
            }
        }
    }

    Process {
        id: setGifProc
        property string selFile: ""
        command: ["cp", selFile, Paths.assets + "/gifs/current.gif"]
        onExited: code => {
            if (code === 0 && musicPanel.pendingGifIndex >= 0) {
                musicPanel.currentGifIndex = musicPanel.pendingGifIndex
                musicPanel.gifSelectorOpen = false
                gifReloadTimer.start()
            } else {
                musicPanel.isApplyingGif = false
                musicPanel.pendingGifIndex = -1
                danceGifLoader.active = true
            }
        }
    }

    // Title/artist/length/status bind directly to the MPRIS player. Only the
    // playback position needs refreshing (players don't push it continuously),
    // so read player.position on a 1s timer while the panel is open — no process.
    Timer {
        id: posTimer
        interval: 1000
        running: root.musicVisible && !musicPanel.gifSelectorOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: musicPanel.position = musicPanel.player ? musicPanel.player.position : 0
    }
}