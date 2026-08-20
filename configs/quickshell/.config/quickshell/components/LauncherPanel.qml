import Quickshell
import "../Common"
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

PanelWindow {
    id: launcherPanel
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true }
    margins { top: 40; bottom: 10; left: root.launcherVisible ? 6 : -450 }
    implicitWidth: 420
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on margins.left { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.7)
        radius: 20

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: 12
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: root.activeTab === 0 ? Theme.alpha(Theme.color5, 0.2) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            StyledText {
                                text: "󰀻"
                                color: root.activeTab === 0 ? Theme.color5 : Theme.color8
                                font.pixelSize: 14
                            }
                            StyledText {
                                text: "Apps"
                                color: root.activeTab === 0 ? Theme.color5 : Theme.color8
                                font.pixelSize: 13
                                font.bold: root.activeTab === 0
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = 0
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: root.activeTab === 1 ? Theme.alpha(Theme.color13, 0.2) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            StyledText {
                                text: "󰸉"
                                color: root.activeTab === 1 ? Theme.color13 : Theme.color8
                                font.pixelSize: 14
                            }
                            StyledText {
                                text: "Walls"
                                color: root.activeTab === 1 ? Theme.color13 : Theme.color8
                                font.pixelSize: 13
                                font.bold: root.activeTab === 1
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = 1
                                if (!root.wallsLoaded) root.loadWallpapers()
                                wallSearchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 15
                    visible: root.activeTab === 0

                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 12
                        border.width: searchInput.activeFocus ? 1 : 0
                        border.color: Theme.color5
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10
                            StyledText {
                                text: ""
                                color: Theme.color8
                                font.pixelSize: 14
                            }
                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Theme.foreground
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                clip: true
                                Text {
                                    text: "Search apps..."
                                    color: Theme.color8
                                    visible: !parent.text
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    font: parent.font
                                }
                                onTextChanged: {
                                    root.searchTerm = text.toLowerCase()
                                    root.selectedIndex = 0
                                }
                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Down) {
                                        root.selectedIndex = Math.min(root.selectedIndex + 1, root.filteredApps.length - 1)
                                        appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up) {
                                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                                        appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (root.filteredApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredApps.length)
                                            root.launchApp(root.filteredApps[root.selectedIndex])
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.launcherVisible = false
                                        searchInput.text = ""
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Tab) {
                                        root.activeTab = 1
                                        if (!root.wallsLoaded) root.loadWallpapers()
                                        wallSearchInput.forceActiveFocus()
                                        event.accepted = true
                                    }
                                }
                            }
                            StyledText {
                                visible: searchInput.text.length > 0
                                text: "󰅖"
                                color: Theme.color8
                                font.pixelSize: 12
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: searchInput.text = ""
                                }
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 15
                        clip: true
                        ListView {
                            id: appListView
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            currentIndex: root.selectedIndex
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 100
                            model: root.filteredApps
                            delegate: Rectangle {
                                width: appListView.width
                                height: 48
                                radius: 12
                                color: {
                                    if (index === root.selectedIndex)
                                        return Theme.alpha(Theme.color5, 0.2)
                                    if (appItemMouse.containsMouse)
                                        return Qt.rgba(1, 1, 1, 0.05)
                                    return "transparent"
                                }
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Rectangle {
                                    visible: index === root.selectedIndex
                                    width: 3
                                    height: 22
                                    radius: 2
                                    color: Theme.color5
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    anchors.topMargin: 6
                                    anchors.bottomMargin: 6
                                    spacing: 12
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: Qt.rgba(0, 0, 0, 0.2)
                                        Image {
                                            anchors.centerIn: parent
                                            width: 22
                                            height: 22
                                            source: {
                                                var icon = modelData.icon
                                                if (!icon || icon === "") return "image://icon/application-x-executable"
                                                if (icon.indexOf("/") === 0) return "file://" + icon
                                                return "image://icon/" + icon
                                            }
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            cache: true
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: index === root.selectedIndex ? Theme.color5 : Theme.foreground
                                            font.pixelSize: 13
                                            font.bold: index === root.selectedIndex
                                            elide: Text.ElideRight
                                        }
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.execString
                                            color: Theme.color8
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                            opacity: 0.7
                                        }
                                    }
                                    StyledText {
                                        visible: index === root.selectedIndex
                                        text: "↵"
                                        color: Theme.color5
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                MouseArea {
                                    id: appItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launchApp(modelData)
                                    onContainsMouseChanged: {
                                        if (containsMouse) root.selectedIndex = index
                                    }
                                }
                            }
                            ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                        }
                        StyledText {
                            anchors.centerIn: parent
                            visible: root.filteredApps.length === 0
                            text: "No apps found"
                            color: Theme.color8
                            font.pixelSize: 14
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 10
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            StyledText { text: "↑↓ nav"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "↵ launch"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "tab walls"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "esc close"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 15
                    visible: root.activeTab === 1

                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 12
                        border.width: wallSearchInput.activeFocus ? 1 : 0
                        border.color: Theme.color13
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10
                            StyledText {
                                text: ""
                                color: Theme.color8
                                font.pixelSize: 14
                            }
                            TextInput {
                                id: wallSearchInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Theme.foreground
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                clip: true
                                Text {
                                    text: "Search wallpapers..."
                                    color: Theme.color8
                                    visible: !parent.text
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    font: parent.font
                                }
                                onTextChanged: {
                                    root.wallSearchTerm = text.toLowerCase()
                                    root.wallSelectedIndex = 0
                                }
                                Keys.onPressed: function(event) {
                                    var cols = 3
                                    var total = root.filteredWallpapers.length
                                    if (event.key === Qt.Key_Right) {
                                        root.wallSelectedIndex = Math.min(root.wallSelectedIndex + 1, total - 1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Left) {
                                        root.wallSelectedIndex = Math.max(root.wallSelectedIndex - 1, 0)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Down) {
                                        root.wallSelectedIndex = Math.min(root.wallSelectedIndex + cols, total - 1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up) {
                                        root.wallSelectedIndex = Math.max(root.wallSelectedIndex - cols, 0)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (total > 0 && root.wallSelectedIndex >= 0 && root.wallSelectedIndex < total)
                                            root.applyWallpaper(root.filteredWallpapers[root.wallSelectedIndex])
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.launcherVisible = false
                                        wallSearchInput.text = ""
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Tab) {
                                        root.activeTab = 0
                                        searchInput.forceActiveFocus()
                                        event.accepted = true
                                    }
                                }
                            }
                            StyledText {
                                visible: wallSearchInput.text.length > 0
                                text: "󰅖"
                                color: Theme.color8
                                font.pixelSize: 12
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wallSearchInput.text = ""
                                }
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 15
                        clip: true
                        GridView {
                            id: wallGridView
                            anchors.fill: parent
                            anchors.margins: 10
                            cellWidth: Math.floor(width / 3)
                            cellHeight: cellWidth * 0.65 + 30
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            cacheBuffer: 400
                            model: root.filteredWallpapers
                            delegate: Item {
                                width: wallGridView.cellWidth
                                height: wallGridView.cellHeight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    radius: 10
                                    color: {
                                        if (index === root.wallSelectedIndex)
                                            return Theme.alpha(Theme.color13, 0.25)
                                        if (wallItemMouse.containsMouse)
                                            return Qt.rgba(1, 1, 1, 0.08)
                                        return Qt.rgba(0, 0, 0, 0.2)
                                    }
                                    border.width: {
                                        if (modelData.path === root.currentWallpaper) return 2
                                        if (index === root.wallSelectedIndex) return 1
                                        return 0
                                    }
                                    border.color: modelData.path === root.currentWallpaper ? Theme.color2 : Theme.color13
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 2
                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 7
                                                color: Qt.rgba(0.3, 0.3, 0.3, 0.3)
                                                visible: wallThumbImage.status !== Image.Ready
                                            }
                                            ClippingRectangle {
                                                anchors.fill: parent
                                                radius: 7
                                                color: "transparent"
                                                Image {
                                                    id: wallThumbImage
                                                    anchors.fill: parent
                                                    source: root.thumbsReady ? "file://" + Paths.cache + "/wallpaper-thumbs/" + wallThumbImage.thumbHash + ".jpg" : ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    smooth: false
                                                    asynchronous: true
                                                    cache: true
                                                    sourceSize.width: 180
                                                    sourceSize.height: 120
                                                    // md5 of the full path — matches create_thumbs' naming
                                                    property string thumbHash: Qt.md5(modelData.path)
                                                    onStatusChanged: {
                                                        if (status === Image.Error && modelData.path)
                                                            source = "file://" + modelData.path
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                visible: modelData.path === root.currentWallpaper
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: 3
                                                width: 16
                                                height: 16
                                                radius: 8
                                                color: Theme.color2
                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: "󰄬"
                                                    color: Theme.background
                                                    font.pixelSize: 10
                                                }
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 22
                                            text: modelData.name
                                            color: {
                                                if (modelData.path === root.currentWallpaper) return Theme.color2
                                                if (index === root.wallSelectedIndex) return Theme.color13
                                                return Theme.foreground
                                            }
                                            font.pixelSize: 8
                                            font.family: Theme.fontFamily
                                            font.bold: index === root.wallSelectedIndex || modelData.path === root.currentWallpaper
                                            elide: Text.ElideMiddle
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                    MouseArea {
                                        id: wallItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.applyWallpaper(modelData)
                                        onContainsMouseChanged: {
                                            if (containsMouse) root.wallSelectedIndex = index
                                        }
                                    }
                                }
                            }
                            ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                        }
                        StyledText {
                            anchors.centerIn: parent
                            visible: root.wallsLoaded && root.filteredWallpapers.length === 0
                            text: "No wallpapers found"
                            color: Theme.color8
                            font.pixelSize: 14
                        }
                        StyledText {
                            anchors.centerIn: parent
                            visible: !root.wallsLoaded && root.wallpaperList.length === 0
                            text: "Loading..."
                            color: Theme.color8
                            font.pixelSize: 13
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 10
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            StyledText { text: "←→↑↓ nav"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "↵ apply"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "tab apps"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "esc close"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: root
        function onLauncherVisibleChanged() {
            if (root.launcherVisible) {
                searchInput.text = ""
                wallSearchInput.text = ""
                root.selectedIndex = 0
                root.wallSelectedIndex = 0
                loadUsageProc.running = true
                currentWallProc.running = true
                focusDelayTimer.start()
            } else {
                searchInput.text = ""
                wallSearchInput.text = ""
                searchInput.focus = false
                wallSearchInput.focus = false
            }
        }
        function onWallSelectedIndexChanged() {
            if (root.activeTab === 1)
                wallGridView.positionViewAtIndex(root.wallSelectedIndex, GridView.Contain)
        }
    }

    Timer {
        id: focusDelayTimer
        interval: 50
        repeat: false
        onTriggered: {
            launcherPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            exclusiveReleaseTimer.start()
        }
    }

    Timer {
        id: exclusiveReleaseTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.activeTab === 0)
                searchInput.forceActiveFocus()
            else {
                if (!root.wallsLoaded) root.loadWallpapers()
                wallSearchInput.forceActiveFocus()
            }
            launcherPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
        }
    }
}
