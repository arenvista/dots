import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "./Common"
import "./components"

ShellRoot {
    id: root

    property bool dashboardVisible: false
    property bool musicVisible: false
    property bool launcherVisible: false
    property bool wifiVisible: false
    property bool btVisible: false
    property var pfpFiles: []
    property string searchTerm: ""
    // Native desktop-entry list (reactive; populates asynchronously).
    property var appList: {
        var apps = DesktopEntries.applications.values
        var out = []
        for (var i = 0; i < apps.length; i++)
            if (!apps[i].noDisplay) out.push(apps[i])
        return out
    }
    property var appUsage: ({})
    property var filteredApps: {
        var source = appList
        var usage = appUsage
        if (searchTerm !== "") {
            var result = []
            for (var i = 0; i < source.length; i++) {
                var entry = source[i]
                if (entry.name.toLowerCase().includes(searchTerm) || entry.execString.toLowerCase().includes(searchTerm)) {
                    result.push(entry)
                }
            }
            source = result
        }
        var sorted = source.slice().sort(function(a, b) {
            var countA = usage[a.id] || 0
            var countB = usage[b.id] || 0
            if (countB !== countA) return countB - countA
            return a.name.localeCompare(b.name)
        })
        return sorted
    }
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

    function toggleLauncher() { launcherVisible = !launcherVisible }

    function toggleDashboard() {
        dashboardVisible = !dashboardVisible
        if (dashboardVisible) { wifiVisible = false; btVisible = false }
    }
    function toggleMusic() { musicVisible = !musicVisible }

    function toggleWifi() {
        wifiVisible = !wifiVisible
        if (wifiVisible) { btVisible = false; dashboardVisible = false }
    }

    function toggleBluetooth() {
        btVisible = !btVisible
        if (btVisible) { wifiVisible = false; dashboardVisible = false }
    }


    Component.onCompleted: {
        loadUsageProc.running = true
        currentWallProc.running = true
        thumbDirProc.running = true
    }

    function launchApp(app) {
        app.execute()
        var usage = appUsage
        var updated = {}
        for (var key in usage) updated[key] = usage[key]
        updated[app.id] = (updated[app.id] || 0) + 1
        appUsage = updated
        saveUsageProc.command = ["bash", "-c", "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"", "_", JSON.stringify(updated), Paths.state + "/app_usage.json"]
        saveUsageProc.running = true
        root.launcherVisible = false
    }

    function applyWallpaper(wallpaper) {
        root.currentWallpaper = wallpaper.path
        root.walApplying = true
        applyWallProc.command = ["bash", "-c", "exec \"$1/scripts/applwal.sh\" \"$2\"", "_", Paths.config, wallpaper.path]
        // applyWallProc.command = ["bash", "-c",
        //     "notify-send '" + wallpaper.path + "' ~/wallpapers/current && " +
        //     "ln -sf '" + wallpaper.path + "' ~/wallpapers/current && " +
        //     "swww img '" + wallpaper.path + "' --transition-type any --transition-duration 2 & " +
        //     "wal -i '" + wallpaper.path + "' -n -q && " +
        //     "sleep 1"
        // ]
        applyWallProc.running = true
    }

    function loadWallpapers() {
        root.wallpaperList = []
        root.wallsLoaded = false
        root.thumbsReady = false
        wallpaperListProc.running = true
    }

    Process {
        id: thumbDirProc
        command: ["bash", "-c", "mkdir -p ~/.cache/wallpaper-thumbs"]
        onExited: root.loadWallpapers()
    }

    Process {
        id: wallpaperListProc
        command: ["bash", "-c", "find ~/wallpapers/favorites -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' | sort"]
        stdout: SplitParser {
            onRead: data => {
                var path = data.trim()
                if (path.length === 0) return
                var parts = path.split("/")
                var name = parts[parts.length - 1]
                var current = root.wallpaperList.slice()
                current.push({ name: name, path: path })
                root.wallpaperList = current
            }
        }
        onExited: {
            root.wallsLoaded = true
            thumbGenProc.running = true
        }
    }

    Process {
        id: thumbGenProc
        command: ["uv", "run", Paths.config + "/scripts/create_thumbs.py"]
        onExited: root.thumbsReady = true
    }

    Process {
        id: applyWallProc
        // applwal.sh does the whole "apply theme everywhere" chain (swww, wal,
        // waybar, swaync, colorizers, blurred copy). Theme reloads colors itself
        // via a watched FileView, so we only clear the applying flag here.
        onExited: root.walApplying = false
    }

    Process {
        id: currentWallProc
        command: ["bash", "-c", "readlink -f ~/wallpapers/current 2>/dev/null || echo ''"]
        stdout: SplitParser { onRead: data => root.currentWallpaper = data.trim() }
    }

    Process {
        id: loadUsageProc
        command: ["bash", "-c", "cat \"$1\" 2>/dev/null || echo '{}'", "_", Paths.state + "/app_usage.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try { root.appUsage = JSON.parse(data.trim()) } catch(e) { root.appUsage = {} }
            }
        }
    }

    Process { id: saveUsageProc }


    Dashboard {}
    MusicPanel {}
    WifiPanel {}
    BluetoothPanel {}
    LauncherPanel {}

    IpcHandler {
        target: "launcher"
        function toggle() {
            root.activeTab = 0
            root.toggleLauncher()
        }
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
        target: "wallpaper"
        function toggle() {
            if (!root.launcherVisible) {
                root.activeTab = 1
                root.toggleLauncher()
            } else if (root.activeTab === 1) {
                root.toggleLauncher()
            } else {
                root.activeTab = 1
                if (!root.wallsLoaded) root.loadWallpapers()
            }
        }
    }
    IpcHandler {
        target: "wifi"
        function toggle() { root.toggleWifi() }
    }
    IpcHandler {
        target: "bluetooth"
        function toggle() { root.toggleBluetooth() }
    }
}
