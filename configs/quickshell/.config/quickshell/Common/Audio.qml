pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// The default output (Pipewire sink): volume, mute and a matching glyph, shared
// by the bar, dashboard, audio panel and OSD.
Singleton {
    id: audio

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!(sink && sink.ready && sink.audio)
    readonly property int volume: ready ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: ready && sink.audio.muted
    readonly property string glyph: muted || volume === 0 ? "󰝟" : volume < 50 ? "󰖀" : "󰕾"

    // Setting a volume above 0 also unmutes: moving the level means "I want sound".
    function setVolume(percent) {
        if (!ready) return
        sink.audio.volume = Math.max(0, percent) / 100
        if (percent > 0 && sink.audio.muted) sink.audio.muted = false
    }

    function toggleMute() {
        if (ready) sink.audio.muted = !sink.audio.muted
    }

    // Keep the default sink's audio properties live.
    PwObjectTracker { objects: audio.sink ? [audio.sink] : [] }
}
