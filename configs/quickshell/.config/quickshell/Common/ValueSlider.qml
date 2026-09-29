import QtQuick

// icon + draggable bar + percent row (volume / brightness).
// Bind `value` (0..100; may exceed 100, e.g. boosted volume) and `barColor`;
// handle `moved(percent)` to apply. Scrolling over the row steps by 5.
// Set `iconInteractive: true` + handle `iconClicked()` for e.g. mute, and
// bind `muted` to dim the bar while muted.
Row {
    id: slider
    property string icon: ""
    property color barColor: Theme.foreground
    property int value: 0
    property int minValue: 0
    property bool muted: false
    property bool iconInteractive: false
    signal moved(int percent)
    signal iconClicked()

    width: parent ? parent.width : 0
    spacing: 10

    // Accumulated wheel delta, so touchpads (many small events) step at the
    // same rate as a mouse wheel (120 per notch).
    property real wheelAccum: 0

    function nudge(delta) {
        moved(Math.max(minValue, Math.min(100, value + delta)))
    }

    WheelHandler {
        target: null
        onWheel: event => {
            slider.wheelAccum += event.angleDelta.y
            while (slider.wheelAccum >= 120) { slider.wheelAccum -= 120; slider.nudge(5) }
            while (slider.wheelAccum <= -120) { slider.wheelAccum += 120; slider.nudge(-5) }
        }
    }

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
            width: parent.width * Math.min(slider.value, 100) / 100
            height: parent.height
            radius: 4
            color: slider.barColor
            opacity: slider.muted ? 0.35 : 1
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
        text: slider.muted ? "muted" : slider.value + "%"
        color: Theme.color8
        font.pixelSize: 11
        font.family: Theme.fontFamily
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }
}
