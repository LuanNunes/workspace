#!/usr/bin/env bash
# Move the focused window to the same COLUMN of another desktop.
#
# Symlinked to ~/.config/aerospace/move-to-desktop.sh by macos/bootstrap.sh, and
# called from the alt-ctrl-<n> bindings in aerospace.toml.
#
# Why a script at all: AeroSpace bindings are static. `move-node-to-workspace`
# takes a literal workspace number, and there is no placeholder for "whichever
# screen I am on", so the trio layout forces you to do (desktop-1)*3+column in
# your head every time. This does that arithmetic.
#
# The column is derived from the CURRENT workspace, not from the monitor name —
# deliberately. Reading the monitor would mean repeating the monitor->column
# mapping that aerospace.toml already owns, and the two copies would drift the
# first time a panel is replaced. The trio numbering is the single source:
#
#   workspace = (desktop - 1) * 3 + column,  column in 1..3
#   so column = ((workspace - 1) % 3) + 1
#
# Usage: move-to-desktop.sh <desktop 1..3>
set -euo pipefail

AEROSPACE=/opt/homebrew/bin/aerospace

desktop="${1:?usage: move-to-desktop.sh <desktop 1..3>}"
case "$desktop" in
  1|2|3) ;;
  *) echo "desktop must be 1, 2 or 3 — got '$desktop'" >&2; exit 2 ;;
esac

current="$("$AEROSPACE" list-workspaces --focused)"

# Anything outside 1..9 is a workspace AeroSpace auto-created for a monitor with
# no assignment of its own. It has no column, so the arithmetic below would be
# meaningless — land on the centre of the target desktop instead of guessing.
if [[ "$current" =~ ^[1-9]$ ]]; then
  column=$(( (current - 1) % 3 + 1 ))
else
  column=2
fi

"$AEROSPACE" move-node-to-workspace --focus-follows-window "$(( (desktop - 1) * 3 + column ))"
