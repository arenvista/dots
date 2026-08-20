pragma Singleton

import Quickshell

// Central path singleton so nothing hardcodes /home/<user>.
// `config` is the directory shell.qml was loaded from, so assets resolve
// correctly no matter where the config lives or who runs it.
Singleton {
    id: paths

    readonly property string home: Quickshell.env("HOME")
    readonly property string config: Quickshell.shellRoot
    readonly property string assets: config + "/assets"
    readonly property string cache: home + "/.cache"
    // runtime state (app usage etc.) — kept out of the config/git repo
    readonly property string state: home + "/.local/state/quickshell"

    // file:// URL for a path under the config dir, e.g. fileUrl("assets/gifs/current.gif")
    function fileUrl(rel) {
        return "file://" + config + "/" + rel
    }
}
