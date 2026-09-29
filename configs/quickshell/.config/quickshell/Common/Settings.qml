pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persistent UI choices, saved as JSON in the state dir. Picking an avatar or
// a music gif only records its path here; nothing is copied into the config
// dir (and so the git repo). An empty value means "use the bundled default".
Singleton {
    id: settings

    property alias avatar: adapter.avatar
    property alias musicGif: adapter.musicGif

    FileView {
        path: Paths.state + "/settings.json"
        printErrors: false  // no file until the first pick; the defaults apply
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property string avatar: ""    // absolute path; "" = assets/pfps/pfp.jpg
            property string musicGif: ""  // absolute path; "" = assets/gifs/current.gif
        }
    }
}
