#!/bin/bash
# The cp lines below are relative, so run from this script's own directory.
cd "$(dirname "$0")" || exit 1

mkdir -p "$HOME/.config/systemd/user"
echo "Copying Files"
cp ./systemd/org-sync.path $HOME/.config/systemd/user/
cp ./systemd/org-sync.service $HOME/.config/systemd/user/


systemctl --user daemon-reload
systemctl --user enable --now org-sync.path
journalctl --user -u org-sync.service --no-pager -n 20
