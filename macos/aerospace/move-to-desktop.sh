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
# first time a panel is replaced. The grid numbering is the single source:
#
#   workspace = (desktop - 1) * COLUMNS + column,  column in 1..COLUMNS
#   so column = ((workspace - 1) % COLUMNS) + 1
#
# Usage: move-to-desktop.sh <desktop 1..3>
set -euo pipefail

AEROSPACE=/opt/homebrew/bin/aerospace
CONFIG="$HOME/.config/aerospace/aerospace.toml"

desktop="${1:?usage: move-to-desktop.sh <desktop 1..3>}"
case "$desktop" in
  1|2|3) ;;
  *) echo "desktop must be 1, 2 or 3 — got '$desktop'" >&2; exit 2 ;;
esac

# COLUMNS IS NOT ALWAYS 3, and hardcoding it was a bug worth spelling out. Both
# layouts have three desktops, but the two-screen one has two columns and six
# workspaces — so on the everyday clamshell desk the trio arithmetic sent every
# alt-ctrl-3 to workspace 7, 8 or 9. Those do not exist in layout-2mon.toml:
# they are outside its `persistent-workspaces` and no alt-<n> binds them, so the
# window went somewhere invisible that the keyboard could not reach.
#
# The generated config's header names the fragment it was merged from, and that
# is the only thing on the machine that knows which layout is actually LOADED —
# the monitor count can disagree with it for as long as it takes apply-layout.py
# to notice a display change. Fall back to the monitor count when the header is
# missing, which means someone bypassed apply-layout.py.
if grep -q 'layout-3mon' "$CONFIG" 2>/dev/null; then
  columns=3
elif grep -q 'layout-2mon' "$CONFIG" 2>/dev/null; then
  columns=2
elif [[ "$("$AEROSPACE" list-monitors | grep -c .)" -ge 3 ]]; then
  columns=3
else
  columns=2
fi

last=$(( 3 * columns ))
current="$("$AEROSPACE" list-workspaces --focused)"

# Anything outside the grid is a workspace AeroSpace auto-created for a monitor
# with no assignment of its own, or one stranded by an earlier layout switch. It
# has no column, so the arithmetic below would be meaningless — land on the
# primary column of the target desktop instead of guessing.
if [[ "$current" =~ ^[0-9]+$ ]] && (( current >= 1 && current <= last )); then
  column=$(( (current - 1) % columns + 1 ))
else
  column=2   # the primary screen in both layouts
fi

"$AEROSPACE" move-node-to-workspace --focus-follows-window \
  "$(( (desktop - 1) * columns + column ))"
