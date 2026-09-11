#!/usr/bin/env bash
# Bring the FRONTMOST app's windows back — the keyboard version of clicking its
# icon in the Dock.
#
# Symlinked to ~/.config/aerospace/raise-frontmost.sh by macos/bootstrap.sh, and
# called from the alt-shift-m binding in aerospace.toml.
#
# WHAT IT IS FOR: a minimised window is out of reach of everything else here.
# AeroSpace 0.21.3 has no unminimize command, and the window leaves the tiling
# tree, so alt-backtick cannot see it; AltTab lists windows, and a window in the
# Dock is not one it can offer. The plain macOS switcher does not help either,
# because it activates an APP, never a window: an app whose windows are all
# minimised — or that has none at all, which is where cmd+w leaves Finder and
# Claude — comes to the front with nothing to show.
#
# The Dock icon is the one thing that works, because a click there sends a
# REOPEN event rather than an activation. `open -b` sends that same event, and
# AppKit's default handling of it is exactly what is wanted: when the app has no
# visible window it un-minimises the last one, or creates one if there is none.
# Both halves of the problem, one call. Verified on Spotify, Slack and Teams —
# minimised, AeroSpace saw zero windows, and `open -b` alone brought each back.
#
# NOTHING HERE TOUCHES THE ACCESSIBILITY API, and that is deliberate. An earlier
# draft cleared AXMinimized window by window through System Events, which worked
# but made the key only as reliable as a permission that was observed dropping
# out mid-session (`osascript is not allowed assistive access`, -25211). Both
# `lsappinfo` and `open` go through LaunchServices, which asks for nothing.
#
# WHERE THE WINDOW LANDS: `open -b` on an app with no windows CREATES one, so
# on-window-detected fires and the app's rule sends it to its usual workspace.
# Un-minimising an existing window creates nothing, the rule stays silent, and
# it was seen coming back both on the rule's workspace and on the visible one.
# alt-shift-<n> moves it if it lands somewhere unhelpful.
set -uo pipefail

# lsappinfo answers in its own quoted format, e.g.
#   "CFBundleIdentifier"="com.spotify.client"
asn="$(lsappinfo front)"
[[ -n "$asn" ]] || exit 0

bundle_id="$(lsappinfo info -only bundleid "$asn" |
    sed -n 's/.*"CFBundleIdentifier"="\(.*\)"/\1/p')"
[[ -n "$bundle_id" ]] || exit 0

open -b "$bundle_id"
