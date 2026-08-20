import QtQuick

// 44x24 iOS-style toggle. Bind `checked`; handle `toggled()` to flip state.
Rectangle {
    id: toggle
    property bool checked: false
    signal toggled()

    width: 44
    height: 24
    radius: 12
    color: checked ? Theme.color5 : Qt.rgba(0.3, 0.3, 0.3, 0.5)
    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        width: 20
        height: 20
        radius: 10
        y: 2
        x: toggle.checked ? 22 : 2
        color: Theme.background
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled()
    }
}
