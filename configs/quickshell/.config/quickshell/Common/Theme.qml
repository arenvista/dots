pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Central theme singleton: shared font + pywal colors.
// Colors are loaded (and live-reloaded) directly from ~/.cache/wal/colors.json
// via a watched FileView, so they update even when pywal runs outside the shell.
// The values below are the fallback palette (Catppuccin Mocha) used before the
// first load / when the cache is missing.
Singleton {
    id: theme

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"

    // All 16 wal colors, indexable. Fallback values keep the named aliases below
    // at their previous defaults (indices 1,2,4,5,8,13).
    property var palette: [
        "#45475a", "#f38ba8", "#a6e3a1", "#fab387",
        "#f9e2af", "#89b4fa", "#94e2d5", "#bac2de",
        "#6c7086", "#f38ba8", "#a6e3a1", "#f9e2af",
        "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8"
    ]

    // Named aliases kept for existing call sites.
    readonly property color color1: palette[1]
    readonly property color color2: palette[2]
    readonly property color color4: palette[4]
    readonly property color color5: palette[5]
    readonly property color color8: palette[8]
    readonly property color color13: palette[13]

    // Return `c` with its alpha replaced by `a` (0..1).
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function applyColors(txt) {
        try {
            var json = JSON.parse(txt)
            if (json.special) {
                theme.background = json.special.background || theme.background
                theme.foreground = json.special.foreground || theme.foreground
            }
            if (json.colors) {
                var p = theme.palette.slice()
                for (var i = 0; i < 16; i++) {
                    var c = json.colors["color" + i]
                    if (c) p[i] = c
                }
                theme.palette = p
            }
        } catch (e) {}
    }

    FileView {
        id: walColors
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onLoaded: theme.applyColors(text())
        onFileChanged: reload()
    }
}
