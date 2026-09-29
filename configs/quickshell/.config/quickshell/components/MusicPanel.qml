import Quickshell
import "../Common"
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

PanelWindow {
    id: musicPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    // Only anchored to the top edge, so the layer surface is centered and just
    // as wide as the card (a full-width surface would swallow clicks across the
    // whole band). Hidden = shifted up by its full height, picker included.
    anchors { top: true }
    margins { top: root.musicVisible ? 50 : -(implicitHeight + 20) }
    implicitWidth: 440
    implicitHeight: contentColumn.implicitHeight + 20  // + room for the dropdown shadow
    color: "transparent"
    WlrLayershell.keyboardFocus: root.musicVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on margins.top { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Shared with the bar: the player picked here, else the playing one.
    readonly property var player: root.activePlayer
    readonly property string artUrl: player ? player.trackArtUrl : ""
    readonly property int playerCount: Mpris.players.values.length
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
    property int previewGifIndex: 0
    property bool gifSelectorOpen: false
    property bool gifsLoaded: false
    readonly property string defaultGif: Paths.assets + "/gifs/current.gif"
    readonly property string currentGif: Settings.musicGif !== "" ? Settings.musicGif : defaultGif
    readonly property int currentGifIndex: gifFiles.indexOf(currentGif)

    // Repeat: off -> playlist -> track -> off.
    function cycleLoop() {
        var p = player
        if (!p || !p.loopSupported) return
        p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
            : MprisLoopState.None
    }

    function playerIndex() {
        var ps = Mpris.players.values
        for (var i = 0; i < ps.length; i++) if (player && ps[i].dbusName === player.dbusName) return i
        return 0
    }

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
        if (previewGifIndex < 0 || previewGifIndex >= gifFiles.length) return
        Settings.musicGif = gifFiles[previewGifIndex]
        gifSelectorOpen = false
    }

    function loadGifs() {
        if (gifListProc.running) return
        musicPanel.gifsLoaded = false
        gifListProc.running = true
    }

    function gifFileName(path) {
        var parts = path.split("/")
        var name = parts[parts.length - 1]
        return name.replace(".gif", "")
    }

    // Close the picker along with the panel, so it never lingers on screen.
    Connections {
        target: root
        function onMusicVisibleChanged() {
            if (!root.musicVisible) musicPanel.gifSelectorOpen = false
        }
    }

    // Takes the keyboard while the panel holds focus (see the grab in shell.qml).
    Item {
        focus: true
        Keys.onEscapePressed: {
            if (musicPanel.gifSelectorOpen) musicPanel.gifSelectorOpen = false
            else root.musicVisible = false
        }
    }

    Column {
        id: contentColumn
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        // ClippingRectangle so the blurred art respects the rounded corners.
        ClippingRectangle {
            width: 440
            height: 180
            color: Theme.alpha(Theme.background, 0.7)
            radius: 15

            // Album art as a soft, blurred backdrop.
            Image {
                anchors.fill: parent
                source: musicPanel.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 220
                sourceSize.height: 220
                opacity: status === Image.Ready ? 0.3 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 64
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ClippingRectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 8
                            color: Qt.rgba(0, 0, 0, 0.3)
                            visible: coverImage.status === Image.Ready
                            Image {
                                id: coverImage
                                anchors.fill: parent
                                source: musicPanel.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 88
                                sourceSize.height: 88
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

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
                        }
                    }

                    // Which player this is; click to switch when there are several.
                    StyledText {
                        visible: musicPanel.player !== null
                        text: "via " + (musicPanel.player ? musicPanel.player.identity : "")
                            + (musicPanel.playerCount > 1 ? "   󰓡 " + (musicPanel.playerIndex() + 1) + "/" + musicPanel.playerCount : "")
                        color: playerMa.containsMouse && musicPanel.playerCount > 1 ? Theme.color5 : Theme.color8
                        font.pixelSize: 10
                        MouseArea {
                            id: playerMa
                            anchors.fill: parent
                            enabled: musicPanel.playerCount > 1
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cyclePlayer()
                        }
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
                                width: musicPanel.length > 0 ? parent.width * Math.min(1, musicPanel.position / musicPanel.length) : 0
                                height: parent.height
                                radius: 2
                                color: Theme.color5
                            }

                            MouseArea {
                                anchors.fill: parent
                                // A little taller than the 4px bar so it's easy to hit.
                                anchors.topMargin: -6
                                anchors.bottomMargin: -6
                                enabled: musicPanel.player !== null && musicPanel.player.canSeek
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: function(mouse) {
                                    if (musicPanel.length > 0) {
                                        var seekPos = (mouse.x / width) * musicPanel.length
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
                        spacing: 10
                        opacity: musicPanel.hasTrack ? 1.0 : 0.5

                        ModeButton {
                            glyph: "󰒝"
                            active: !!(musicPanel.player && musicPanel.player.shuffle)
                            enabled: !!(musicPanel.player && musicPanel.player.shuffleSupported)
                            onClicked: musicPanel.player.shuffle = !musicPanel.player.shuffle
                        }

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

                        ModeButton {
                            glyph: musicPanel.player && musicPanel.player.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                            active: !!(musicPanel.player && musicPanel.player.loopState !== MprisLoopState.None)
                            enabled: !!(musicPanel.player && musicPanel.player.loopSupported)
                            onClicked: musicPanel.cycleLoop()
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

                        AnimatedImage {
                            anchors.fill: parent
                            source: "file://" + musicPanel.currentGif
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            playing: musicPanel.playerStatus === "Playing"
                            paused: musicPanel.playerStatus !== "Playing"
                            cache: false
                            asynchronous: true
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
            width: 420
            height: 260
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 14
            color: Theme.alpha(Theme.background, 0.75)
            border.color: Qt.rgba(1,1,1,0.1)
            border.width: 1
            visible: musicPanel.gifSelectorOpen
            clip: true

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0,0,0,0.35)
                shadowBlur: 0.5
                shadowVerticalOffset: 4
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
                                    anchors.fill: parent
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
                            enabled: musicPanel.gifFiles.length > 1
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
                            enabled: musicPanel.gifFiles.length > 1
                            onClicked: musicPanel.nextGif()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 85
                        Layout.preferredHeight: 32
                        radius: 8
                        readonly property bool isCurrent: musicPanel.previewGifIndex === musicPanel.currentGifIndex
                        color: {
                            if (isCurrent) return Qt.rgba(1,1,1,0.05)
                            return applyGifMa.pressed ? Theme.color5 : applyGifMa.containsMouse ? Theme.alpha(Theme.color5, 0.35) : Theme.alpha(Theme.color5, 0.18)
                        }
                        border.color: {
                            if (isCurrent) return Qt.rgba(1,1,1,0.08)
                            return applyGifMa.containsMouse ? Theme.color5 : Theme.alpha(Theme.color5, 0.4)
                        }
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: parent.isCurrent ? "󰄬 Current" : "󰸞 Apply"
                            color: {
                                if (parent.isCurrent) return Theme.alpha(Theme.foreground, 0.3)
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
                            cursorShape: !parent.isCurrent ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: !parent.isCurrent && musicPanel.gifFiles.length > 0
                            onClicked: musicPanel.applyGif()
                        }
                    }
                }
            }
        }
    }

    Process {
        id: gifListProc
        command: ["find", Paths.assets + "/gifs", "-maxdepth", "1", "-type", "f", "-name", "*.gif", "!", "-name", "current.gif"]
        stdout: StdioCollector {
            onStreamFinished: {
                var files = text.split("\n").filter(function(f) { return f !== "" })
                files.sort(function(a, b) { return a.localeCompare(b) })
                musicPanel.gifFiles = files
                musicPanel.gifsLoaded = true
                musicPanel.previewGifIndex = Math.max(0, musicPanel.currentGifIndex)
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

    // Shuffle / repeat toggle: accent-colored when on, dimmed when unsupported.
    component ModeButton: Rectangle {
        id: modeBtn
        property string glyph
        property bool active: false
        signal clicked()
        width: 28
        height: 28
        radius: 8
        opacity: enabled ? 1 : 0.3
        color: modeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
        StyledText {
            anchors.centerIn: parent
            text: modeBtn.glyph
            color: modeBtn.active ? Theme.color5 : Theme.alpha(Theme.foreground, 0.45)
            font.pixelSize: 14
        }
        MouseArea {
            id: modeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modeBtn.clicked()
        }
    }
}
