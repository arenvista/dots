import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import "./Common"
import "./Common/calc.js" as Calc
import "./components"

ShellRoot {
    id: root

    property bool dashboardVisible: false
    property bool musicVisible: false
    property bool launcherVisible: false
    property bool wifiVisible: false
    property bool btVisible: false
    property bool audioVisible: false
    // Idle inhibitor on the bar (see Bar.qml). Deliberately not persisted.
    property bool keepAwake: false
    property string searchTerm: ""
    // Terminal for Terminal=true entries: DesktopEntry.execute() ignores that flag.
    readonly property string terminal: Quickshell.env("TERMINAL") || "kitty"
    // Native desktop-entry list (reactive; populates asynchronously).
    property var appList: {
        var apps = DesktopEntries.applications.values
        var out = []
        for (var i = 0; i < apps.length; i++)
            if (!apps[i].noDisplay) out.push(apps[i])
        return out
    }
    // Launch counts keyed by desktop-entry id, persisted in the state dir.
    property var appUsage: ({})
    // Best match first while searching (see matchScore), most-used first
    // otherwise; ties fall back to usage, then name.
    property var filteredApps: {
        var query = searchTerm
        var usage = appUsage
        var scored = []
        for (var i = 0; i < appList.length; i++) {
            var app = appList[i]
            var score = query === "" ? 1 : matchScore(app, query)
            if (score > 0) scored.push({ app: app, score: score, uses: usageOf(app, usage) })
        }
        scored.sort(function(a, b) {
            return (b.score - a.score) || (b.uses - a.uses) || a.app.name.localeCompare(b.app.name)
        })
        return scored.map(function(s) { return s.app })
    }
    // Arithmetic typed into the app search ("12*7", "sqrt(2)") shows a result
    // row above the apps; selectedIndex -1 selects it.
    readonly property var calcResult: Calc.evaluate(searchTerm)
    readonly property string calcText: calcResult === null ? "" : Calc.format(calcResult)
    property int selectedIndex: 0
    property int activeTab: 0
    property string wallSearchTerm: ""
    property var wallpaperList: []
    property var filteredWallpapers: {
        if (wallSearchTerm === "") return wallpaperList
        var result = []
        for (var i = 0; i < wallpaperList.length; i++) {
            if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm)) {
                result.push(wallpaperList[i])
            }
        }
        return result
    }
    property int wallSelectedIndex: 0
    property string currentWallpaper: ""
    property bool wallsLoaded: false
    property bool thumbsReady: false
    property bool walApplying: false

    // Clipboard history for the launcher's Clip tab, newest first.
    property var clipHistory: []
    property string clipSearchTerm: ""
    property int clipSelectedIndex: 0
    readonly property var filteredClips: {
        var q = clipSearchTerm
        if (q === "") return clipHistory
        return clipHistory.filter(function(t) { return t.toLowerCase().includes(q) })
    }

    // Player chosen in the music panel (MPRIS bus name); "" = automatic, i.e.
    // the one that's playing, else the first. The bar and panel both use this.
    property string preferredPlayer: ""
    readonly property var activePlayer: {
        var ps = Mpris.players.values
        if (ps.length === 0) return null
        for (var i = 0; i < ps.length; i++) if (ps[i].dbusName === preferredPlayer) return ps[i]
        for (var j = 0; j < ps.length; j++) if (ps[j].isPlaying) return ps[j]
        return ps[0]
    }

    function cyclePlayer() {
        var ps = Mpris.players.values
        if (ps.length < 2) return
        var current = activePlayer ? activePlayer.dbusName : ""
        var i = 0
        while (i < ps.length && ps[i].dbusName !== current) i++
        preferredPlayer = ps[(i + 1) % ps.length].dbusName
    }

    // One panel at a time: the focus grab below hands the keyboard to the open
    // panel, and with several open it would be arbitrary which one gets it.
    function showOnly(name) {
        launcherVisible = name === "launcher"
        dashboardVisible = name === "dashboard"
        musicVisible = name === "music"
        wifiVisible = name === "wifi"
        btVisible = name === "bluetooth"
        audioVisible = name === "audio"
    }

    function togglePanel(name, visible) {
        if (closedByGrab(name)) return
        showOnly(visible ? "" : name)
    }

    function toggleDashboard() { togglePanel("dashboard", dashboardVisible) }
    function toggleWifi() { togglePanel("wifi", wifiVisible) }
    function toggleBluetooth() { togglePanel("bluetooth", btVisible) }
    function toggleAudio() { togglePanel("audio", audioVisible) }
    function toggleMusic() { togglePanel("music", musicVisible) }

    // Open the launcher on `tab` (0 apps, 1 walls, 2 clipboard), switch to it
    // if the launcher shows another tab, or close it if it's already there.
    function toggleLauncherTab(tab) {
        if (!launcherVisible) {
            if (closedByGrab("launcher")) return
            activeTab = tab
            showOnly("launcher")
        } else if (activeTab === tab) {
            launcherVisible = false
        } else {
            activeTab = tab
        }
        if (launcherVisible && activeTab === 1) loadWallpapers()
    }

    // Click outside to close: one Hyprland focus grab over the open panel.
    // Clicking anywhere else (the bar included) clears it and closes the panel;
    // Hyprland 0.56 swallows that click, so switching panels from the bar takes
    // a second click. closedByGrab() is a safety net in case a clearing click
    // ever does reach the bar: it stops it toggling the panel straight back open.
    // The grab also gives the panel keyboard focus. Panels must not switch to
    // WlrKeyboardFocus.Exclusive: Hyprland clears the grab when they do.
    readonly property var openPanels: {
        var w = []
        if (launcherVisible) w.push(launcherWin)
        if (dashboardVisible) w.push(dashboardWin)
        if (musicVisible) w.push(musicWin)
        if (wifiVisible) w.push(wifiWin)
        if (btVisible) w.push(btWin)
        if (audioVisible) w.push(audioWin)
        return w
    }
    property var grabClosed: ({})
    property real grabClosedAt: 0

    function closedByGrab(name) {
        return grabClosed[name] === true && Date.now() - grabClosedAt < 300
    }

    HyprlandFocusGrab {
        windows: root.openPanels
        active: root.openPanels.length > 0
        onCleared: {
            root.grabClosed = {
                launcher: root.launcherVisible, dashboard: root.dashboardVisible,
                music: root.musicVisible, wifi: root.wifiVisible,
                bluetooth: root.btVisible, audio: root.audioVisible
            }
            root.grabClosedAt = Date.now()
            root.showOnly("")
        }
    }


    Component.onCompleted: {
        currentWallProc.running = true
        loadWallpapers()
    }

    // How well `app` matches the lowercase query `q`: name matches beat the
    // generic name / keywords ("browser" finds Firefox via "Web Browser"),
    // which beat the raw Exec line. 0 = no match.
    function matchScore(app, q) {
        var name = app.name.toLowerCase()
        if (name === q) return 100
        if (name.startsWith(q)) return 80
        var generic = (app.genericName || "").toLowerCase()
        if (startsWord(name, q) || generic.startsWith(q) || startsWord(generic, q)) return 60
        if (name.includes(q)) return 50
        if (generic.includes(q)) return 30
        var keywords = app.keywords
        for (var i = 0; i < keywords.length; i++)
            if (keywords[i].toLowerCase().startsWith(q)) return 25
        if (app.id.toLowerCase().includes(q)) return 20
        if ((app.comment || "").toLowerCase().includes(q)) return 10
        if (app.execString.toLowerCase().includes(q)) return 5
        return 0
    }

    // True if a later word of `s` ("visual studio code") starts with `q`.
    function startsWord(s, q) {
        return s.includes(" " + q) || s.includes("-" + q)
    }

    // Older usage files were keyed by app name rather than id; count both.
    function usageOf(app, usage) {
        var n = usage[app.id] || 0
        if (app.name !== app.id) n += usage[app.name] || 0
        return n
    }

    // `terminal -e <Exec>` for Terminal=true entries (nvim, htop, yazi, ...).
    function terminalCommand(app) {
        var cmd = [root.terminal, "-e"]
        for (var i = 0; i < app.command.length; i++) cmd.push(app.command[i])
        return cmd
    }

    function launchApp(app) {
        if (app.runInTerminal && app.command.length > 0)
            Quickshell.execDetached(terminalCommand(app))
        else
            app.execute()
        var updated = Object.assign({}, appUsage)
        updated[app.id] = (updated[app.id] || 0) + 1
        appUsage = updated
        usageFile.setText(JSON.stringify(updated))
        root.launcherVisible = false
    }

    // Copy the calculator result and close the launcher.
    function copyCalcResult() {
        if (calcText === "") return
        Quickshell.execDetached(["wl-copy", "--", calcText])
        launcherVisible = false
    }

    // Put a history entry back on the clipboard (the watcher then moves it to
    // the top) and close the launcher.
    function copyClip(text) {
        Quickshell.execDetached(["wl-copy", "--", text])
        launcherVisible = false
    }

    function setClips(items) {
        clipHistory = items
        clipStore.json = JSON.stringify(items)
    }

    function addClip(text) {
        // Skip blanks, and huge entries: wl-copy gets the text as one argv
        // entry, which the kernel caps at 128 KiB.
        if (text.trim() === "" || text.length > 20000) return
        var items = clipHistory.filter(function(t) { return t !== text })
        items.unshift(text)
        setClips(items.slice(0, 100))
    }

    function removeClip(text) {
        setClips(clipHistory.filter(function(t) { return t !== text }))
    }

    function clearClips() {
        setClips([])
    }

    function applyWallpaper(wallpaper) {
        root.currentWallpaper = wallpaper.path
        root.walApplying = true
        // A click while applwal.sh is still running queues the newest choice
        // instead of being dropped (Process ignores running = true mid-run).
        if (applyWallProc.running) applyWallProc.queued = wallpaper.path
        else applyWallProc.apply(wallpaper.path)
    }

    // Rescan favorites/ (cheap). The model is only replaced, and thumbnails
    // regenerated, when the file list actually changed.
    function loadWallpapers() {
        if (!wallpaperListProc.running) wallpaperListProc.running = true
    }

    Process {
        id: wallpaperListProc
        command: ["find", Paths.wallpapers + "/favorites", "-maxdepth", "1", "-type", "f",
                  "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.gif",
                  "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")", "!", "-name", ".*"]
        stdout: StdioCollector {
            onStreamFinished: {
                var paths = text.split("\n").filter(function(p) { return p !== "" })
                paths.sort(function(a, b) { return a.localeCompare(b) })
                var old = root.wallpaperList.map(function(w) { return w.path })
                var changed = paths.join("\n") !== old.join("\n")
                if (changed) {
                    root.wallpaperList = paths.map(function(p) {
                        return { name: p.substring(p.lastIndexOf("/") + 1), path: p }
                    })
                }
                root.wallsLoaded = true
                if (changed || !root.thumbsReady) thumbGenProc.running = true
            }
        }
    }

    Process {
        id: thumbGenProc
        command: ["uv", "run", Paths.config + "/scripts/create_thumbs.py"]
        onExited: root.thumbsReady = true
    }

    Process {
        id: applyWallProc
        property string queued: ""
        function apply(path) {
            command = ["bash", Paths.config + "/scripts/applwal.sh", path]
            running = true
        }
        // applwal.sh does the whole "apply theme everywhere" chain (awww, wal,
        // swaync, colorizers, blurred copy). Theme reloads colors itself via a
        // watched FileView (the bar included), so we only clear the flag here.
        onExited: {
            if (queued !== "") {
                var next = queued
                queued = ""
                apply(next)
            } else {
                root.walApplying = false
            }
        }
    }

    Process {
        id: currentWallProc
        command: ["readlink", "-f", Paths.wallpapers + "/current"]
        stdout: SplitParser { onRead: data => root.currentWallpaper = data.trim() }
    }

    FileView {
        id: usageFile
        path: Paths.state + "/app_usage.json"
        printErrors: false  // no file until the first launch
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.appUsage = JSON.parse(text()) } catch (e) { root.appUsage = {} }
        }
    }

    // Text copies as seen by `wl-paste --watch`. Kept in memory only
    // (PersistentProperties survives config reloads, not restarts), and copies
    // password managers flag as sensitive are never recorded.
    PersistentProperties {
        id: clipStore
        reloadableId: "clipboardHistoryJson"
        // A JSON string, because JS arrays can't move to the next config
        // generation's engine ("JSValue can't be reassigned"); strings can.
        property string json: "[]"
        onLoaded: {
            try { root.clipHistory = JSON.parse(json) } catch (e) { root.clipHistory = [] }
        }
    }

    Process {
        id: clipWatcher
        running: true
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c",
                  "if [ \"$CLIPBOARD_STATE\" = data ]; then cat; printf '\\036'; else cat >/dev/null; fi"]
        stdout: SplitParser {
            splitMarker: "\x1e"
            onRead: data => root.addClip(data)
        }
    }


    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Dashboard { id: dashboardWin }
    MusicPanel { id: musicWin }
    WifiPanel { id: wifiWin }
    BluetoothPanel { id: btWin }
    AudioPanel { id: audioWin }
    LauncherPanel { id: launcherWin }
    Osd {}

    IpcHandler {
        target: "launcher"
        function toggle() { root.toggleLauncherTab(0) }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle() { root.toggleLauncherTab(1) }
    }
    IpcHandler {
        target: "clipboard"
        function toggle() { root.toggleLauncherTab(2) }
    }
    IpcHandler {
        target: "dashboard"
        function toggle() { root.toggleDashboard() }
    }
    IpcHandler {
        target: "music"
        function toggle() { root.toggleMusic() }
    }
    IpcHandler {
        target: "wifi"
        function toggle() { root.toggleWifi() }
    }
    IpcHandler {
        target: "bluetooth"
        function toggle() { root.toggleBluetooth() }
    }
    IpcHandler {
        target: "audio"
        function toggle() { root.toggleAudio() }
    }
    IpcHandler {
        target: "keepawake"
        function toggle() { root.keepAwake = !root.keepAwake }
    }
}
