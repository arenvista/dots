pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Battery state from UPower's display device, shared by the bar and the
// dashboard, plus the one-shot low-battery notification.
Singleton {
    id: battery

    readonly property var device: UPower.displayDevice
    readonly property bool ready: device && device.ready
    // False on desktops, so battery widgets can hide themselves.
    readonly property bool present: ready && device.isLaptopBattery
    readonly property int percent: ready ? Math.round(device.percentage * 100) : 100
    readonly property bool charging: ready && device.state === UPowerDeviceState.Charging
    readonly property bool pluggedIn: charging || (ready && (device.state === UPowerDeviceState.FullyCharged
        || device.state === UPowerDeviceState.PendingCharge))
    readonly property int lowThreshold: 15
    readonly property bool low: percent <= lowThreshold && !pluggedIn

    readonly property string glyph: {
        if (charging) return "󰂄"
        var cap = percent
        if (cap >= 90) return "󰁹"
        else if (cap >= 80) return "󰂂"
        else if (cap >= 70) return "󰂁"
        else if (cap >= 60) return "󰂀"
        else if (cap >= 50) return "󰁿"
        else if (cap >= 40) return "󰁾"
        else if (cap >= 30) return "󰁽"
        else if (cap >= 20) return "󰁼"
        else if (cap >= 10) return "󰁻"
        return "󰁺"
    }

    readonly property string statusText: {
        if (!ready) return "Checking..."
        var s = device.state
        if (s === UPowerDeviceState.Charging)
            return "Charging" + (device.timeToFull > 0 ? " · " + formatDuration(device.timeToFull) + " to full" : "")
        if (s === UPowerDeviceState.FullyCharged) return "Fully charged"
        if (s === UPowerDeviceState.PendingCharge) return "Plugged in, not charging"
        return (low ? "Low battery!" : "Discharging")
            + (device.timeToEmpty > 0 ? " · " + formatDuration(device.timeToEmpty) + " left" : "")
    }

    // Seconds -> "1h 45m" / "12m".
    function formatDuration(s) {
        var h = Math.floor(s / 3600)
        var m = Math.round((s - h * 3600) / 60)
        if (m === 60) { h++; m = 0 }
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }

    // Notify once when the battery drops into the low range while discharging;
    // re-arm when charging or back above the threshold.
    property bool lowNotified: false
    onLowChanged: {
        if (low && !lowNotified) {
            lowNotified = true
            Quickshell.execDetached(["notify-send", "-u", "critical", "-i", "battery-caution",
                "Low battery", "Battery at " + percent + "% — plug in your charger."])
        } else if (!low) {
            lowNotified = false
        }
    }
}
