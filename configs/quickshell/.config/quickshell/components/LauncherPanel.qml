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

    // Desktop-entry icon -> image URL, or "" when the icon theme lacks it (the
    // delegate then shows a letter badge; also avoids icon-loader warnings).
    function iconSource(icon) {
        if (!icon) return ""
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, true)
    }

    // Selection runs from -1 (the calculator row, when shown) to the last app.
    function moveAppSelection(delta) {
        var first = root.calcText !== "" ? -1 : 0
        var last = root.filteredApps.length - 1
        if (last < first) return
        root.selectedIndex = Math.max(first, Math.min(last, root.selectedIndex + delta))
        if (root.selectedIndex >= 0)
            appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    }

    function moveClipSelection(delta) {
        var n = root.filteredClips.length
        if (n === 0) return
        root.clipSelectedIndex = Math.max(0, Math.min(n - 1, root.clipSelectedIndex + delta))
        clipListView.positionViewAtIndex(root.clipSelectedIndex, ListView.Contain)
    }

    // Keyboard focus to the active tab's search field (walls rescan on the way in).
    function focusActiveTab() {
        if (root.activeTab === 0) {
            searchInput.forceActiveFocus()
        } else if (root.activeTab === 1) {
            root.loadWallpapers()
            wallSearchInput.forceActiveFocus()
        } else {
            clipSearchInput.forceActiveFocus()
        }
    }

    function showTab(tab) {
        root.activeTab = tab
        focusActiveTab()
    }

    // "Clear all" in the Clip tab needs a second click within 3s.
    property bool clearArmed: false
    Timer { id: clearDisarm; interval: 3000; onTriggered: launcherPanel.clearArmed = false }

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
                    TabButton {
                        icon: "󰀻"
                        label: "Apps"
                        accent: Theme.color5
                        active: root.activeTab === 0
                        onClicked: launcherPanel.showTab(0)
                    }
                    TabButton {
                        icon: "󰸉"
                        label: "Walls"
                        accent: Theme.color13
                        active: root.activeTab === 1
                        onClicked: launcherPanel.showTab(1)
                    }
                    TabButton {
                        icon: "󰅌"
                        label: "Clip"
                        accent: Theme.color4
                        active: root.activeTab === 2
                        onClicked: launcherPanel.showTab(2)
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
                                text: "󰍉"
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
                                    root.searchTerm = text.trim().toLowerCase()
                                    // A calculation starts selected, so Enter copies it.
                                    root.selectedIndex = root.calcText !== "" ? -1 : 0
                                    appListView.positionViewAtBeginning()
                                }
                                Keys.onPressed: function(event) {
                                    var ctrl = event.modifiers & Qt.ControlModifier
                                    if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                                        launcherPanel.moveAppSelection(1)
                                    } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                                        launcherPanel.moveAppSelection(-1)
                                    } else if (event.key === Qt.Key_PageDown) {
                                        launcherPanel.moveAppSelection(8)
                                    } else if (event.key === Qt.Key_PageUp) {
                                        launcherPanel.moveAppSelection(-8)
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (root.selectedIndex === -1)
                                            root.copyCalcResult()
                                        else if (root.selectedIndex < root.filteredApps.length)
                                            root.launchApp(root.filteredApps[root.selectedIndex])
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.launcherVisible = false
                                        searchInput.text = ""
                                    } else if (event.key === Qt.Key_Tab) {
                                        launcherPanel.showTab(1)
                                    } else if (event.key === Qt.Key_Backtab) {
                                        launcherPanel.showTab(2)
                                    } else {
                                        return
                                    }
                                    event.accepted = true
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

                    // Result of arithmetic typed into the search ("12*7", "sqrt(2)").
                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 12
                        visible: root.calcText !== ""
                        color: root.selectedIndex === -1 ? Theme.alpha(Theme.color5, 0.2) : Qt.rgba(0, 0, 0, 0.3)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            spacing: 14
                            StyledText {
                                text: "="
                                color: Theme.color5
                                font.pixelSize: 20
                                font.bold: true
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.calcText
                                    color: Theme.color5
                                    font.pixelSize: 16
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: searchInput.text.trim() + "  ·  ↵ copy"
                                    color: Theme.color8
                                    font.pixelSize: 9
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyCalcResult()
                            onContainsMouseChanged: if (containsMouse) root.selectedIndex = -1
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
                                            id: appIcon
                                            anchors.centerIn: parent
                                            width: 22
                                            height: 22
                                            source: launcherPanel.iconSource(modelData.icon)
                                            sourceSize.width: 44
                                            sourceSize.height: 44
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            cache: true
                                        }
                                        // Letter badge when there's no usable icon.
                                        StyledText {
                                            anchors.centerIn: parent
                                            visible: appIcon.source.toString() === "" || appIcon.status === Image.Error
                                            text: modelData.name.charAt(0).toUpperCase()
                                            color: Theme.color5
                                            font.pixelSize: 14
                                            font.bold: true
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
                                            // "Web Browser" says more than "/usr/lib/firefox/firefox %u".
                                            text: (modelData.runInTerminal ? "󰆍 " : "")
                                                + (modelData.genericName || modelData.comment || modelData.execString)
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
                                text: "󰍉"
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
                                    root.wallSearchTerm = text.trim().toLowerCase()
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
                                        launcherPanel.showTab(2)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Backtab) {
                                        launcherPanel.showTab(0)
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
                            // applwal.sh takes a few seconds (wal + retheming); say so.
                            StyledText {
                                text: root.walApplying ? "󰑐 applying..." : "↵ apply"
                                color: root.walApplying ? Theme.color13 : Theme.color8
                                font.pixelSize: 10
                                opacity: root.walApplying ? 1 : 0.7
                            }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "tab clip"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "esc close"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                        }
                    }
                }

                // Clipboard history (text copies recorded by shell.qml's watcher).
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 15
                    visible: root.activeTab === 2

                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 12
                        border.width: clipSearchInput.activeFocus ? 1 : 0
                        border.color: Theme.color4
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10
                            StyledText {
                                text: "󰍉"
                                color: Theme.color8
                                font.pixelSize: 14
                            }
                            TextInput {
                                id: clipSearchInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Theme.foreground
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                clip: true
                                Text {
                                    text: "Search clipboard..."
                                    color: Theme.color8
                                    visible: !parent.text
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    font: parent.font
                                }
                                onTextChanged: {
                                    root.clipSearchTerm = text.trim().toLowerCase()
                                    root.clipSelectedIndex = 0
                                    clipListView.positionViewAtBeginning()
                                }
                                Keys.onPressed: function(event) {
                                    var ctrl = event.modifiers & Qt.ControlModifier
                                    var n = root.filteredClips.length
                                    if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                                        launcherPanel.moveClipSelection(1)
                                    } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                                        launcherPanel.moveClipSelection(-1)
                                    } else if (event.key === Qt.Key_PageDown) {
                                        launcherPanel.moveClipSelection(8)
                                    } else if (event.key === Qt.Key_PageUp) {
                                        launcherPanel.moveClipSelection(-8)
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (root.clipSelectedIndex < n)
                                            root.copyClip(root.filteredClips[root.clipSelectedIndex])
                                    } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                                        if (root.clipSelectedIndex < n)
                                            root.removeClip(root.filteredClips[root.clipSelectedIndex])
                                        root.clipSelectedIndex = Math.max(0, Math.min(root.clipSelectedIndex, root.filteredClips.length - 1))
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.launcherVisible = false
                                    } else if (event.key === Qt.Key_Tab) {
                                        launcherPanel.showTab(0)
                                    } else if (event.key === Qt.Key_Backtab) {
                                        launcherPanel.showTab(1)
                                    } else {
                                        return
                                    }
                                    event.accepted = true
                                }
                            }
                            StyledText {
                                visible: clipSearchInput.text.length > 0
                                text: "󰅖"
                                color: Theme.color8
                                font.pixelSize: 12
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: clipSearchInput.text = ""
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
                            id: clipListView
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            currentIndex: root.clipSelectedIndex
                            model: root.filteredClips
                            delegate: Rectangle {
                                id: clipRow
                                required property string modelData
                                required property int index
                                readonly property bool selected: index === root.clipSelectedIndex
                                readonly property string trimmed: modelData.trim()
                                readonly property int lineCount: modelData.split("\n").length
                                width: ListView.view.width
                                height: 44
                                radius: 12
                                color: selected ? Theme.alpha(Theme.color4, 0.2)
                                    : clipMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Rectangle {
                                    visible: clipRow.selected
                                    width: 3
                                    height: 22
                                    radius: 2
                                    color: Theme.color4
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    anchors.topMargin: 5
                                    anchors.bottomMargin: 5
                                    spacing: 1
                                    StyledText {
                                        Layout.fillWidth: true
                                        // First line only; the rest is summarized below.
                                        text: clipRow.trimmed.split("\n")[0]
                                        color: clipRow.selected ? Theme.color4 : Theme.foreground
                                        font.pixelSize: 12
                                        font.bold: clipRow.selected
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: (clipRow.lineCount > 1 ? clipRow.lineCount + " lines · " : "") + clipRow.modelData.length + " chars"
                                        color: Theme.color8
                                        font.pixelSize: 9
                                        opacity: 0.7
                                    }
                                }
                                MouseArea {
                                    id: clipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.copyClip(clipRow.modelData)
                                    onContainsMouseChanged: if (containsMouse) root.clipSelectedIndex = clipRow.index
                                }
                            }
                            ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                        }
                        Column {
                            anchors.centerIn: parent
                            visible: root.filteredClips.length === 0
                            spacing: 4
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.clipHistory.length === 0 ? "Clipboard history is empty" : "No matches"
                                color: Theme.color8
                                font.pixelSize: 14
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: root.clipHistory.length === 0
                                text: "Copied text shows up here until the shell restarts"
                                color: Theme.color8
                                font.pixelSize: 10
                                opacity: 0.7
                            }
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
                            StyledText { text: "↵ copy"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "⇧del remove"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: launcherPanel.clearArmed ? "click again to clear" : "󰆴 clear all"
                                color: launcherPanel.clearArmed ? Theme.color1 : Theme.color8
                                font.pixelSize: 10
                                opacity: launcherPanel.clearArmed || clearMa.containsMouse ? 1 : 0.7
                                MouseArea {
                                    id: clearMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (launcherPanel.clearArmed) {
                                            launcherPanel.clearArmed = false
                                            root.clearClips()
                                        } else {
                                            launcherPanel.clearArmed = true
                                            clearDisarm.restart()
                                        }
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            StyledText { text: "tab apps"; color: Theme.color8; font.pixelSize: 10; opacity: 0.7 }
                        }
                    }
                }
            }
        }
    }

    component TabButton: Rectangle {
        id: tab
        property string icon
        property string label
        property color accent
        property bool active: false
        signal clicked()
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 8
        color: active ? Theme.alpha(accent, 0.2) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            StyledText {
                text: tab.icon
                color: tab.active ? tab.accent : Theme.color8
                font.pixelSize: 14
            }
            StyledText {
                text: tab.label
                color: tab.active ? tab.accent : Theme.color8
                font.pixelSize: 13
                font.bold: tab.active
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tab.clicked()
        }
    }

    Connections {
        target: root
        function onLauncherVisibleChanged() {
            if (root.launcherVisible) {
                searchInput.text = ""
                wallSearchInput.text = ""
                clipSearchInput.text = ""
                root.selectedIndex = 0
                root.wallSelectedIndex = 0
                root.clipSelectedIndex = 0
                appListView.positionViewAtBeginning()
                clipListView.positionViewAtBeginning()
                currentWallProc.running = true
                // The focus grab (shell.qml) gives this surface the keyboard.
                launcherPanel.focusActiveTab()
            } else {
                searchInput.text = ""
                wallSearchInput.text = ""
                clipSearchInput.text = ""
                searchInput.focus = false
                wallSearchInput.focus = false
                clipSearchInput.focus = false
                launcherPanel.clearArmed = false
            }
        }
        // Tab switches can also arrive over IPC while the launcher is open.
        function onActiveTabChanged() {
            if (root.launcherVisible) launcherPanel.focusActiveTab()
        }
        function onWallSelectedIndexChanged() {
            if (root.activeTab === 1)
                wallGridView.positionViewAtIndex(root.wallSelectedIndex, GridView.Contain)
        }
    }
}
