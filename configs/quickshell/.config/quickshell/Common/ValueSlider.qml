import QtQuick

// icon + draggable bar + percent row (volume / brightness).
// Bind `value` (0..100) and `barColor`; handle `moved(percent)` to apply.
// Set `iconInteractive: true` + handle `iconClicked()` for e.g. mute.
Row {
    id: slider
    property string icon: ""
    property color barColor: Theme.foreground
    property int value: 0
    property int minValue: 0
    property bool iconInteractive: false
    signal moved(int percent)
    signal iconClicked()

    width: parent ? parent.width : 0
    spacing: 10

    Text {
        width: 25
        height: 24
        text: slider.icon
        color: slider.barColor
        font.pixelSize: 18
        font.family: Theme.fontFamily
        verticalAlignment: Text.AlignVCenter
        MouseArea {
            anchors.fill: parent
            enabled: slider.iconInteractive
            cursorShape: slider.iconInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: slider.iconClicked()
        }
    }

    Rectangle {
        id: track
        width: slider.width - 75
        height: 8
        anchors.verticalCenter: parent.verticalCenter
        radius: 4
        color: Qt.rgba(0, 0, 0, 0.3)
        Rectangle {
            width: parent.width * slider.value / 100
            height: parent.height
            radius: 4
            color: slider.barColor
            Behavior on width { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function apply(mouse) {
                var percent = Math.round((mouse.x / width) * 100)
                percent = Math.max(slider.minValue, Math.min(100, percent))
                slider.moved(percent)
            }
            onClicked: mouse => apply(mouse)
            onPositionChanged: mouse => { if (pressed) apply(mouse) }
        }
    }

    Text {
        width: 40
        height: 24
        text: slider.value + "%"
        color: Theme.color8
        font.pixelSize: 11
        font.family: Theme.fontFamily
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }
}
