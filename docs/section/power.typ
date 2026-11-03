#import "@local/folio:0.1.0": *

= Power and battery

The machine is a ThinkPad T480 (`20L6`): an i5-8350U rated at 15 W, Intel UHD
620 graphics, a 1080p panel, and two batteries --- `BAT0` inside, `BAT1` the
removable one at the back. Battery tuning is split across four owners, each
doing the part only it can do:

#table(
  columns: (auto, 1fr),
  [*Owner*], [*What it controls*],
  [TLP], [Kernel and device knobs: CPU turbo and energy preference, PCIe ASPM,
    runtime PM, radios, charge thresholds.],
  [throttled], [The CPU package power limits (PL1/PL2), rewritten every few
    seconds because the T480's firmware keeps resetting them.],
  [Hyprland], [GPU work: blur, shadows, animations, panel refresh rate.],
  [quickshell], [The plug/unplug event that tells Hyprland and user services
    to switch profile.],
)

== Already in place

Before this round of changes the basics were covered:

- TLP with charge thresholds of 75/80 % on both batteries (`/etc/tlp.conf`),
  plus `tlp-rdw` for radio switching on NetworkManager events.
- throttled, which works around the T480's aggressive embedded-controller
  throttling on AC.
- zram swap (zstd, 7.7 GB) with zswap disabled on the kernel command line.
- S3 deep sleep selected (`/sys/power/mem_sleep` reads `s2idle [deep]`).
- hypridle dimming, locking and blanking the panel; `paccache.timer` and
  `fstrim.timer`.

== CPU: power limits and turbo

=== throttled

The stock `/etc/throttled.conf` lets the CPU sustain 29 W on battery --- about
twice its rated 15 W TDP. The battery section now sets `PL1_Tdp_W: 15`; the AC
section is unchanged at 44 W. PL2 (the short burst limit) stays at 44 W, so
bursts still feel snappy.

#warning(title: "Undervolting")[
  BIOS `N24ET81W (1.56)` almost certainly locks the voltage MSRs (Lenovo's fix
  for Plundervolt, CVE-2019-11157). To check, set `CORE: -50` under
  `[UNDERVOLT.BATTERY]`, then read `journalctl -u throttled -n 30`. If it
  reports that undervolting is unsupported or locked, put it back to 0.
]

=== TLP drop-in

TLP was running on its defaults apart from the thresholds.
`system/etc/tlp.d/10-battery.conf` adds:

#table(
  columns: (auto, auto, 1fr),
  [*Setting*], [*Value*], [*Effect*],
  [`CPU_BOOST_ON_BAT`], [`0`], [No turbo: the CPU stays at or below its
    1.7 GHz base clock. The largest single saving, at a real cost to
    single-threaded speed.],
  [`CPU_HWP_DYN_BOOST_ON_BAT`], [`0`], [Stops the kernel raising the
    minimum P-state for I/O-bound tasks.],
  [`PCIE_ASPM_ON_BAT`], [`powersave`], [PCIe link power saving (L0s/L1);
    the default leaves the BIOS's choice. Deliberately not `powersupersave`:
    see _The NVMe_ below.],
  [`DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE`], [`bluetooth wwan`], [Radios with
    nothing connected are switched off when the charger is pulled.],
  [`CPU_MAX_PERF_ON_BAT`], [_commented_], [A further cap if turbo-off is not
    enough.],
)

TLP's own battery defaults were already right and are left alone:

- `CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power`
- `RUNTIME_PM_ON_BAT=auto`
- `WIFI_PWR_ON_BAT=on`
- `USB_AUTOSUSPEND=1`

#remark[
  `/etc/modprobe.d/` sets `iwlwifi power_save=0`. That only sets the driver
  default; TLP still turns Wi-Fi power saving on when on battery. It was kept
  as is.
]

=== The NVMe

The SSD is a KingFast drive on a DRAM-less Silicon Motion SM2263 controller
(it borrows 64 MiB of system RAM as a host memory buffer). Drives on this
controller family have a history on Linux of I/O stalls and controller resets
in the deepest power states. Two separate mechanisms are involved:

#table(
  columns: (auto, auto, 1fr),
  [*Mechanism*], [*Setting*], [*Here*],
  [PCIe ASPM \ (link states)], [`PCIE_ASPM_ON_BAT`], [`powersave`: L0s/L1 only.
    `powersupersave` would add the L1.1/L1.2 substates, which is where the
    risk is, for a small extra saving.],
  [NVMe APST \ (drive's own idle states)], [`nvme_core.default_ps_max_latency_us`],
    [Kernel default (100000 µs: every state allowed). This was already the case
    before these changes, with no NVMe errors logged, so it is left alone.],
)

If the disk ever stalls (`journalctl -k -g nvme` shows timeouts, resets or
"controller is down"), first set `PCIE_ASPM_ON_BAT=default`. If that doesn't
help, cap APST with `nvme_core.default_ps_max_latency_us=` on the kernel
command line. Run `sudo nvme id-ctrl /dev/nvme0 | grep '^ps'` (from `nvme-cli`)
to list each power state's entry and exit latency, then pick a value just
below the deepest state's. That blocks only that state; `0` turns APST off
entirely.

#remark[
  The kernel journal only went back to the current boot when this was checked,
  so "no errors" covers one boot's history, not months.
]

Because TLP now switches radios, the `systemd-rfkill` service and socket are
masked, as TLP's documentation asks --- otherwise the two fight over radio state
at boot.

== Compositor: the battery profile

On the UHD 620 the costliest thing Hyprland does is blur: 3 passes behind every
inactive window, which are 75 % opaque, plus a 35 px shadow under each. The
battery profile turns these off.

`hyprland.lua` reads `/sys/class/power_supply/AC/online` once each time it
loads (Hyprland's Lua has `io`) and sets:

#table(
  columns: (auto, auto, auto),
  [*Setting*], [*On AC*], [*On battery*],
  [`decoration.blur.enabled`], [on], [off],
  [`decoration.shadow.enabled`], [on], [off],
  [`animations.enabled`], [on], [off],
  [`eDP-1` mode], [`preferred` (60 Hz)], [`1920x1080@48`],
  [`decoration.blur.xray`], [on], [on],
)

`xray` is now on all the time. Tiled windows never overlap in the scrolling
layout, so it only changes floating windows: they blur the cached wallpaper
instead of re-blurring whatever is under them.

The panel's 48 Hz mode appears in `hyprctl monitors` under `availableModes`. It
was tested at runtime (it reports `47.999 Hz`), and a reload restores 60 Hz.

#important(title: "Why a reload, not hyprctl eval")[
  Switching profile is just `hyprctl reload`. If the profile were applied with
  `hyprctl eval` instead, the next config save (Hyprland reloads on save) would
  silently put AC settings back on battery. Doing it at load time makes
  `hyprland.lua` the only source of truth.

  A reload does _not_ re-run the `hyprland.start` hook (checked: still one
  quickshell and one miniserve after a reload), so the
  quickshell → reload → quickshell loop it could otherwise cause cannot happen.
]

== The plug/unplug hook

`quickshell/Common/Battery.qml` watches UPower's `onBattery` property and, when it
flips, runs `~/.config/hypr/scripts/powermode.sh`. The script:

+ runs `hyprctl reload`, so `hyprland.lua` picks the matching profile;
+ stops `syncthing.service` (a user unit) on battery and starts it again on AC.
  Set `PAUSE_SYNCTHING=0` at the top of the script to keep syncing on battery.

TLP and throttled detect the AC state on their own (TLP through udev, throttled
by polling sysfs), so the hook does not touch them.

#remark[
  The hook is meant for _changes_. If you log in on battery, Hyprland already
  starts in the battery profile (it reads the AC state at load). Whether
  syncthing stops depends on quickshell: UPower's properties fill in
  asynchronously, so `onBattery` may flip once at startup and run the hook,
  which stops syncthing; if it doesn't flip, syncthing runs until the next plug
  or unplug. Either way nothing breaks: a reload does not restart quickshell.
]

== Idle: suspend on battery

hypridle's timeline, measured from the last input:

#table(
  columns: (auto, 1fr),
  [*After*], [*Action*],
  [2.5 min], [Dim the panel to 10 % (`scripts/idle-dim.sh`), keyboard backlight off],
  [5 min], [Lock (`loginctl lock-session`)],
  [5.5 min], [Panel off (DPMS)],
  [15 min], [*Suspend, on battery only*],
)

The 15-minute listener checks `AC/online` when its timer fires, so AC keeps
the old no-auto-suspend behaviour. Unplugging partway through an idle stretch
does not trigger it until the next idle stretch. Deep sleep (S3) is already
selected, so a suspended T480 costs very little. quickshell's keep-awake toggle
still pauses every timer.

== Video decoding

The GPU decodes H.264, HEVC and VP9 in hardware, but not AV1. YouTube prefers
AV1, which then gets decoded on the CPU --- one of the most expensive things a
laptop can do on battery.

- `hyprland.lua` sets `LIBVA_DRIVER_NAME=iHD`. Both `intel-media-driver` (iHD)
  and `libva-intel-driver` (i965) are installed, and this makes the choice
  explicit.
- Firefox gets `media.av1.enabled = false` from a `user.js` in the default
  profile (`ee392ds5.default-release`). That file is not in this repo: Firefox
  profiles are not stowed. YouTube then falls back to VP9.

To check, play a video and open `about:support` → _Media_, or run `vainfo`
(from `libva-utils`) and look for `iHD` and the `VAProfileVP9` entries.

== Packages

The new `system.power` feature in `deps.toml` owns the power stack, and
`cli.monitoring` is now on, with `btop` in place of `bpytop`. Both are in the
`desktop` profile.

#table(
  columns: (auto, auto, 1fr),
  [*Package*], [*Feature*], [*Why*],
  [`tlp`, `tlp-rdw`], [`system.power`], [Already installed; now declared.],
  [`throttled`], [`system.power`], [Already installed; now declared.],
  [`powertop`], [`system.power`], [_Measuring only._ Its `--auto-tune` fights TLP.],
  [`libva-utils`], [`system.power`], [`vainfo`, to confirm hardware decoding.],
  [`intel-gpu-tools`], [`system.power`], [`intel_gpu_top`: see what blur
    and animations cost.],
  [`nvme-cli`], [`system.power`], [NVMe power states (APST) and health.],
  [`btop`, `duf`], [`cli.monitoring`], [Process, battery and disk monitors.],
)

== Installing

Through the manager, `system.power` is in the `desktop` profile; its setup
steps (`src/tui/features/system_power.py`) copy the `/etc` files. stow only
links into `$HOME`, so root-owned files live in `system/etc/` and are copied
rather than linked. By hand (the paths are relative to the repo root):

```sh
cd ~/dots
sudo pacman -S --needed powertop libva-utils intel-gpu-tools nvme-cli btop duf
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
sudo install -Dm644 system/etc/tlp.d/10-battery.conf /etc/tlp.d/10-battery.conf
sudo tlp start
sudo install -Dm644 system/etc/throttled.conf /etc/throttled.conf
sudo systemctl restart throttled
```

#warning[
  `system/etc/throttled.conf` replaces the whole file. Edit the repo copy and
  reinstall it --- edits made only in `/etc` are lost on the next install.
]

== Checking it works

Unplug the charger, wait a few seconds, then:

```sh
tlp-stat -c | grep 10-battery          # the drop-in is being read
sudo tlp-stat -p                       # no_turbo = 1, EPP balance_power
journalctl -u throttled -n 20          # PL1 15 W applied on battery
hyprctl getoption decoration:blur:enabled   # false
hyprctl monitors | grep -A1 eDP-1      # 1920x1080@47.999
systemctl --user is-active syncthing   # inactive
journalctl -k -g nvme                  # no timeouts or resets
upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep energy-rate
```

`energy-rate` (or `sudo powertop`'s overview) is the number to watch: compare it
before and after a change, with the same brightness and workload.

`sudo cat /sys/kernel/debug/dri/*/i915_edp_psr_status` shows whether the panel
uses Panel Self Refresh. That could not be checked without root.

== Battery health

Read on 2026-10-04:

#table(
  columns: (auto, auto, auto, auto, auto),
  [*Battery*], [*Design*], [*Full now*], [*Health*], [*Cycles*],
  [`BAT0` (internal)], [24.0 Wh], [15.4 Wh], [64 %], [416],
  [`BAT1` (external)], [71.0 Wh], [56.0 Wh], [79 %], [352],
)

At the time `BAT0` was at 6 % on AC while `BAT1` charged at 22.9 W. That may
just be the order the firmware charges in, but run `sudo tlp-stat -b` to check
that `BAT0` does climb back up.

With 75/80 % thresholds the batteries never fill. Before a long day away from
power, run `sudo tlp fullcharge` to fill to 100 % (it lasts until the next
boot, when the configured thresholds return), or `sudo tlp fullcharge BAT1` to
fill just the external battery.

== Left out, on purpose

- *power-profiles-daemon, auto-cpufreq, tuned:* each conflicts with TLP.
  *thermald* conflicts with throttled.
- *`powertop --auto-tune`:* it overwrites TLP's settings until reboot.
- *systemd-oomd:* not power related. On Arch no slice has `ManagedOOM*` set,
  so enabling the service does nothing without extra drop-ins. With 16 GB RAM
  plus zram it is not worth it.
- *hyprsunset:* no config uses it, and the manifest only lists packages
  something needs.
- *Tailscale down on battery:* idle `tailscaled` is cheap, and taking it down
  from a user script needs `tailscale set --operator=$USER`. Do it by hand when
  it matters: `sudo tailscale down`.

== Files

#table(
  columns: (auto, 1fr),
  [*Path*], [*Role*],
  [`system/etc/tlp.d/10-battery.conf`], [TLP battery drop-in → `/etc/tlp.d/`],
  [`system/etc/throttled.conf`], [Full throttled config → `/etc/`],
  [`configs/hypr/…/hyprland.lua`], [`onBattery` at load; battery profile; `LIBVA_DRIVER_NAME`],
  [`configs/hypr/…/scripts/powermode.sh`], [Reload Hyprland; pause or resume syncthing],
  [`configs/hypr/…/hypridle.conf`], [Suspend after 15 min, on battery only],
  [`configs/quickshell/…/Common/Battery.qml`], [Runs `powermode.sh` when `UPower.onBattery` changes],
  [`deps.toml`], [`system.power` feature; `cli.monitoring` on, `btop`],
  [`src/tui/features/system_power.py`], [Copies the `/etc` files, masks rfkill],
  [Firefox profile `user.js`], [`media.av1.enabled = false` (not in this repo)],
)
