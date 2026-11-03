#import "@local/folio:0.1.0": *

#show: notes.with(
  title: "sybil-dotfiles",
  subtitle: "How this machine is set up, and why",
  author: "Aren Vista",
  course: "ThinkPad T480 · Arch Linux · Hyprland",
  date: "2026-10-04",
  toc: true,
)

// One file per topic under section/. Each imports folio itself, since an
// included file does not see this file's imports.
#include "section/power.typ"
