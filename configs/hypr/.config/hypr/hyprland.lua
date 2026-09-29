-- HYPRLAND LUA CONFIG ------------------------------------------------------

local home = os.getenv("HOME")
local mainMod = "SUPER"

-- Cursor theme and size are set once here and reused by the env vars,
-- `hyprctl setcursor` at startup, and the cursor submap's restore.
-- 24 is a size Bibata actually ships (…22, 24, 28…); 25 isn't.
local cursorTheme = "Bibata-Modern-Ice"
local cursorSize = 24
local cursorDefaults = { inactive_timeout = 3, hide_on_key_press = true }

-- ENVIRONMENT VARIABLES ----------------------------------------------------

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_THEME", cursorTheme)
hl.env("XCURSOR_SIZE", tostring(cursorSize))
hl.env("HYPRCURSOR_THEME", cursorTheme)
hl.env("HYPRCURSOR_SIZE", tostring(cursorSize))
-- Electron apps (Discord, VSCodium, ...) run natively on Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- CORE CONFIG ----------------------------------------------------------------

hl.config({
    cursor = cursorDefaults,
    xwayland = {
        force_zero_scaling = true,
    },
    misc = {
        disable_hyprland_logo = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
        sensitivity = 0, -- -1.0 .. 1.0, 0 = no modification
    },
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 1,
        col = {
            active_border = "rgb(8d8d8d)",
            inactive_border = "rgb(2a2b36)",
        },
        layout = "scrolling",
    },
    scrolling = {
        fullscreen_on_one_column = false,
        column_width = 0.5,
        explicit_column_widths = "0.25, 0.333, 0.5, 0.666, 0.75, 1.0",
        focus_fit_method = 1,
        follow_focus = true,
    },
    decoration = {
        rounding = 16,
        active_opacity = 1.0,
        inactive_opacity = 0.75,
        dim_inactive = true,
        dim_strength = 0.05,
        shadow = {
            enabled = true,
            range = 35,
            render_power = 4,
            color = "rgba(00000050)",
            offset = { 0, 8 },
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            noise = 0.006,
            brightness = 1.03,
            contrast = 1.02,
            vibrancy = 0.25,
            vibrancy_darkness = 0.6,
            new_optimizations = true,
            xray = false,
            popups = true,
            special = true,
        },
    },
    animations = {
        enabled = true,
    },
})

-- 0.51+ gesture syntax — 3-finger swipe to change workspaces on the laptop
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- MONITORS -------------------------------------------------------------------

hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = "1" })
hl.monitor({ output = "DP-2", mode = "5120x1440@119.97", position = "auto", scale = "1" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" }) -- catch-all fallback

-- WORKSPACE RULES ------------------------------------------------------------

-- Dropdown terminal (SUPER+Return): the first toggle spawns kitty with the
-- scratchterm class, which the window rule below floats at 85%x70%.
hl.workspace_rule({ workspace = "special:scratchterm", on_created_empty = "kitty --class scratchterm" })

-- Monitor pinning is currently disabled: a new workspace opens on whichever
-- monitor is focused.

-- hl.workspace_rule({ workspace = "1", default = false })

-- for i = 1, 10 do
--     hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2" })
-- end

-- ANIMATION CURVES -----------------------------------------------------------

hl.curve("bounce", { type = "bezier", points = { { 0.0, 1.25 }, { 0.15, 1.0 } } })
hl.curve("buttery", { type = "bezier", points = { { 0.1, 1.15 }, { 0.15, 1.02 } } })
hl.curve("smooth", { type = "bezier", points = { { 0.0, 0.0 }, { 0.12, 1.0 } } })

local animations = {
    { leaf = "windowsIn", speed = 4.5, bezier = "bounce", style = "slide" },
    { leaf = "windowsOut", speed = 3.5, bezier = "smooth", style = "slide" },
    { leaf = "windowsMove", speed = 4, bezier = "buttery", style = "slide" },
    { leaf = "fadeIn", speed = 3.5, bezier = "smooth" },
    { leaf = "fadeOut", speed = 3, bezier = "smooth" },
    { leaf = "fadeDim", speed = 4, bezier = "smooth" },
    { leaf = "fadeShadow", speed = 4, bezier = "smooth" },
    { leaf = "workspaces", speed = 4.5, bezier = "buttery", style = "slidefade 10%" },
    { leaf = "specialWorkspace", speed = 4.5, bezier = "buttery", style = "slidefadevert -15%" },
    { leaf = "border", speed = 7, bezier = "smooth" },
    { leaf = "layersIn", speed = 4, bezier = "bounce", style = "slide" },
    { leaf = "layersOut", speed = 3, bezier = "smooth", style = "slide" },
}
for _, a in ipairs(animations) do
    a.enabled = true
    hl.animation(a)
end

-- PLUGINS --------------------------------------------------------------------

-- DEFAULT PROGRAMS -----------------------------------------------------------

local terminal = "kitty"
local fileManager = "kitty -e yazi"
local restartQuickshell = "pkill -x quickshell; quickshell"
-- Fixed quoting: the wallpaper path is now interpolated once, cleanly, and ~
-- is expanded in Lua rather than hoping the shell/rofi does it inside quotes.
local menu = "rofi -show drun -theme-str \"dummywall{background-image:url('"
    .. home
    .. "/wallpapers/current.jpg"
    .. "', height);}\""

-- KEYBINDS: GENERAL ----------------------------------------------------------

hl.bind(
    mainMod .. " + f",
    hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
    { description = "Maximize App Window" }
)

hl.bind(mainMod .. " + q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }))

-- Screenshots. The saved variant also copies to the clipboard (tee) and
-- creates the target directory if it's missing. exec_cmd already runs through
-- a shell, and slurp's overlay has no fade-out (see LAYER RULES), so grim can
-- run as soon as the selection is made.
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd([[geom=$(slurp) && grim -g "$geom" - | wl-copy]]))
hl.bind(
    mainMod .. " + SHIFT + N",
    hl.dsp.exec_cmd(
        [[mkdir -p ~/Pictures/screenshots && geom=$(slurp) && grim -g "$geom" - | tee ~/Pictures/screenshots/"$(date +%Y-%m-%d_%H-%M-%S)".png | wl-copy]]
    )
)

-- pidof guard: a second press while locked doesn't start another hyprlock
hl.bind(mainMod .. " + SHIFT + CTRL + ALT + l", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

-- Restart quickshell (bar and panels)
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd(restartQuickshell))

-- Quickshell panels, via the IpcHandler targets in quickshell's shell.qml
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs ipc call dashboard toggle"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))

-- KEYBINDS: SCROLLING LAYOUT -------------------------------------------------
-- Layout-aware ops go through hl.dsp.layout (layoutmsg) so the built-in
-- scrolling layout handles them.

-- Focus
hl.bind(mainMod .. " + l", hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + h", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + k", hl.dsp.layout("focus u"))
hl.bind(mainMod .. " + j", hl.dsp.layout("focus d"))

-- Move the entire layout left/right
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + comma", hl.dsp.layout("move -col"))

-- Move the active window into the adjacent column
hl.bind(mainMod .. " + CTRL + period", hl.dsp.layout("movewindowto r"))
hl.bind(mainMod .. " + CTRL + comma", hl.dsp.layout("movewindowto l"))
hl.bind(mainMod .. " + CTRL + h", hl.dsp.layout("movewindowto l"), { repeating = true })
hl.bind(mainMod .. " + CTRL + l", hl.dsp.layout("movewindowto r"), { repeating = true })
hl.bind(mainMod .. " + CTRL + p", hl.dsp.layout("promote"))

-- Resize columns (two equivalent chord styles kept on purpose)
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Swapping. NOTE: the converter emitted duplicate ALT+h/l binds (swapcol AND
-- window.swap); only one can win. Kept swapcol for horizontal (plugin-aware),
-- window.swap for vertical within a column.
hl.bind(mainMod .. " + ALT + h", hl.dsp.layout("swapcol l"), { repeating = true })
hl.bind(mainMod .. " + ALT + l", hl.dsp.layout("swapcol r"), { repeating = true })
hl.bind(mainMod .. " + ALT + k", hl.dsp.window.swap({ direction = "u" }), { repeating = true })
hl.bind(mainMod .. " + ALT + j", hl.dsp.window.swap({ direction = "d" }), { repeating = true })

-- KEYBINDS: WORKSPACES -------------------------------------------------------

-- Switch (mainMod + [0-9]) and move window (mainMod + SHIFT + [0-9])
for i = 1, 10 do
    local key = tostring(i % 10) -- 10 lives on the 0 key
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspaces (scratchpads)
local specials = {
    { key = "Backspace", name = "magic" },
    { key = "Delete", name = "magic-second" },
    { key = "Tab", name = "magic-third" },
    { key = "grave", name = "magic-fourth" },
}
for _, s in ipairs(specials) do
    hl.bind(mainMod .. " + " .. s.key, hl.dsp.workspace.toggle_special(s.name))
    hl.bind(mainMod .. " + SHIFT + " .. s.key, hl.dsp.window.move({ workspace = "special:" .. s.name }))
end

-- Dropdown terminal (see WORKSPACE RULES)
hl.bind(mainMod .. " + Return", hl.dsp.workspace.toggle_special("scratchterm"))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Throw the active workspace at the other monitor
local function moveActiveWorkspaceToMonitor(dir)
    return function()
        local w = hl.get_active_workspace()
        if not w then
            return
        end
        hl.dispatch(hl.dsp.workspace.move({ workspace = w.id, monitor = dir }))
    end
end
hl.bind(mainMod .. " + t", moveActiveWorkspaceToMonitor("r"))
hl.bind(mainMod .. " + SHIFT + t", moveActiveWorkspaceToMonitor("l"))

-- KEYBINDS: MEDIA / VOLUME / BRIGHTNESS --------------------------------------
-- Switched amixer -> wpctl (PipeWire-native, respects the default sink and
-- clamps at 100%). locked = works on the lockscreen too.

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
    { repeating = true, locked = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { repeating = true, locked = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +5%"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { repeating = true, locked = true })

local kbptrConfig = home .. "/.config/hypr/config"

-- Long-bracket strings so the inner shell quoting doesn't need escaping
local cursorShow = [[hyprctl eval 'hl.config({ cursor = { inactive_timeout = 0, hide_on_key_press = false } })']]
local enterSubmap = [[hyprctl dispatch 'hl.dsp.submap("cursor")']]

-- Jump-then-fine-tune. wl-kbptr exits non-zero when cancelled
-- (cancellation_status_code=1 in its config), so aborting the jump leaves the
-- cursor settings and submap untouched.
hl.bind(
    mainMod .. " + r",
    hl.dsp.exec_cmd("wl-kbptr -c '" .. kbptrConfig .. "' && " .. cursorShow .. " && " .. enterSubmap)
)

-- Enter fine-tune mode directly (no jump)
hl.bind(mainMod .. " + a", hl.dsp.exec_cmd(cursorShow .. "; " .. enterSubmap))

hl.define_submap("cursor", function()
    -- Movement
    hl.bind("j", hl.dsp.exec_cmd("wlrctl pointer move 0 10"), { repeating = true })
    hl.bind("k", hl.dsp.exec_cmd("wlrctl pointer move 0 -10"), { repeating = true })
    hl.bind("l", hl.dsp.exec_cmd("wlrctl pointer move 10 0"), { repeating = true })
    hl.bind("h", hl.dsp.exec_cmd("wlrctl pointer move -10 0"), { repeating = true })
    -- Clicks
    hl.bind("s", hl.dsp.exec_cmd("wlrctl pointer click left"))
    hl.bind("d", hl.dsp.exec_cmd("wlrctl pointer click middle"))
    hl.bind("f", hl.dsp.exec_cmd("wlrctl pointer click right"))
    -- Scrolling
    hl.bind("e", hl.dsp.exec_cmd("wlrctl pointer scroll 10 0"), { repeating = true })
    hl.bind("r", hl.dsp.exec_cmd("wlrctl pointer scroll -10 0"), { repeating = true })
    hl.bind("t", hl.dsp.exec_cmd("wlrctl pointer scroll 0 -10"), { repeating = true })
    hl.bind("g", hl.dsp.exec_cmd("wlrctl pointer scroll 0 10"), { repeating = true })
    -- Exit & restore cursor settings. Runs in-process, and leaves the submap
    -- first so the keyboard can't get stranded in it.
    hl.bind("escape", function()
        hl.dispatch(hl.dsp.submap("reset"))
        hl.config({ cursor = cursorDefaults })
    end)
end)

-- WINDOW RULES ---------------------------------------------------------------

hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Per-app opacity
local appOpacity = {
    { class = "(?i)thunar", opacity = "0.9 1" },
    { class = "org.pwmt.zathura", opacity = "0.9 1" },
    { class = "firefox", opacity = "0.9 override 0.85 override" },
    { class = "obsidian", opacity = "0.88 1" },
}
for _, r in ipairs(appOpacity) do
    hl.window_rule({ match = { class = r.class }, opacity = r.opacity })
end

hl.window_rule({
    name = "mpv-float",
    match = { class = "mpv" },
    float = true,
    size = "640 360",
    center = true,
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    match = { float = true },
    center = true,
})

hl.window_rule({
    name = "scratchterm",
    match = { class = "scratchterm" },
    float = true,
    size = { "monitor_w * 0.85", "monitor_h * 0.7" },
    center = true,
})

-- LAYER RULES ----------------------------------------------------------------
-- Blur behind each surface; ignore_alpha = 0 leaves fully transparent pixels
-- unblurred. "quickshell" is confirmed via `hyprctl layers`.

for _, ns in ipairs({ "rofi", "swaync-control-center", "quickshell" }) do
    hl.layer_rule({
        match = { namespace = ns },
        blur = true,
        ignore_alpha = 0,
    })
end

-- slurp's selection overlay: no fade-out, so the screenshot binds can run
-- grim immediately without capturing it
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })

-- STARTUP --------------------------------------------------------------------

hl.on("hyprland.start", function()
    -- Hyprland exports its session env to systemd/D-Bus itself, but not
    -- necessarily before this hook runs. Chaining guarantees the polkit agent
    -- (a systemd user unit) starts with WAYLAND_DISPLAY already exported.
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user start hyprpolkitagent"
    )

    -- Compositor-side setup
    hl.exec_cmd("hyprctl setcursor " .. cursorTheme .. " " .. cursorSize)
    hl.exec_cmd("wal -R -n")

    -- Shell / UI
    hl.exec_cmd(restartQuickshell)
    hl.exec_cmd("swaync")
    hl.exec_cmd("awww-daemon")

    -- Background services
    hl.exec_cmd("hypridle")
    hl.exec_cmd("kdeconnect-indicator")
    hl.exec_cmd("syncthing")
    -- Loopback only: nothing in ~/.config/firefox should be reachable from the LAN
    hl.exec_cmd(
        'miniserve -i 127.0.0.1 -i ::1 "$HOME/.config/firefox/" --index home.html --header "Cache-Control: no-cache, no-store, must-revalidate"'
    )
end)
