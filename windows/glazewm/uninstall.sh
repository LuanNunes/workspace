#!/usr/bin/env bash
# Undo the GlazeWM + Zebar setup, returning Windows to its pre-install state.
#
#   ./windows/glazewm/uninstall.sh --dry-run   list what would change, touch nothing
#   ./windows/glazewm/uninstall.sh --apply     actually undo it
#
# Written against the state captured before the install, so each step reverses
# one specific thing that was added rather than guessing. The install touched
# exactly these places:
#
#   1. ~/scoop/apps/{glazewm,zebar}  + shims + Start Menu shortcuts   (Scoop)
#   2. %USERPROFILE%\.glzr                    (written by the apps on first run)
#   3. HKCU\...\Policies\System\DisableLockWorkstation   (to free up Win+L)
#   4. A shortcut in the Startup folder       (only if autostart was set up)
#   5. %APPDATA%\zebar and %LOCALAPPDATA%\com.glzr.zebar  (Zebar's downloaded
#      marketplace packs and its WebView2 cache — ~76 MB, and outside both
#      ~/.glzr and ~/scoop, so nothing else would ever clean them up)
#
# Step 3 needs an elevated shell: the Policies subtree is writable only by
# administrators, which is also why setting it up required elevation. This
# script detects that and tells you what to run instead of failing silently.
#
# The repo side is deliberately NOT touched — windows/glazewm/ and the sync.sh
# entry are version-controlled, so `git` is the right tool to remove them.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() { sed -n '2,5p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 1; }

case "${1:-}" in
  --dry-run) APPLY=0 ;;
  --apply)   APPLY=1 ;;
  *)         usage ;;
esac

# %USERPROFILE% as a WSL path — same helper as ./windows/sync.sh.
win_home() {
  local p
  p="$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" || true
  if [[ -n "${p:-}" ]]; then wslpath -u "$p"; else echo "/mnt/c/Users/$USER"; fi
}

WIN="$(win_home)"
STARTUP="$WIN/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
POLICY_ROOT='HKCU\Software\Microsoft\Windows\CurrentVersion\Policies'

# reg.exe is invoked directly rather than through `cmd.exe /c "reg query ..."`.
# Routing it through cmd.exe means the registry path crosses two layers of quote
# parsing — WSL's interop and then cmd's — and comes out mangled: queries for
# keys that exist come back as "cannot find the specified key". A revert script
# that reports "not set" for a policy that IS set would leave it behind without
# saying so, which is the one failure this script must not have.
REG=/mnt/c/Windows/System32/reg.exe

# Run a Windows command, or just print it under --dry-run.
run_win() {
  if (( APPLY )); then (cd /mnt/c && cmd.exe /c "$1" 2>&1 | tr -d '\r' | sed 's/^/    /')
  else echo "    would run: $1"; fi
}

step() { printf '\n=== %s ===\n' "$1"; }

(( APPLY )) || echo "DRY RUN — nothing will be changed."

# ---------------------------------------------------------------------------
step "1/5  Stop the running processes"
# GlazeWM restores every window it was managing when it exits cleanly, so stop
# it before removing anything. glazewm-watcher is the sidecar that relaunches
# it after a crash — it has to go first, or it would resurrect the WM.

# Snapshot the process list once, into a variable. Piping tasklist straight
# into `grep -q` looks tidier but is a trap here: grep exits at the first match
# and the resulting SIGPIPE kills tasklist upstream, which `set -o pipefail`
# then reports as a failed pipeline. The check silently answered "not running"
# for processes that were running.
tasks="$(cd /mnt/c && tasklist.exe 2>/dev/null | tr -d '\r')"

for proc in glazewm-watcher.exe glazewm.exe zebar.exe; do
  if grep -qi "^${proc//./\\.}[[:space:]]" <<<"$tasks"; then
    echo "  running: $proc"
    run_win "taskkill /IM $proc /F"
  else
    echo "  not running: $proc"
  fi
done

# ---------------------------------------------------------------------------
step "2/5  Remove the autostart shortcut"
shopt -s nullglob
shortcuts=("$STARTUP"/GlazeWM*.lnk "$STARTUP"/Zebar*.lnk)
shopt -u nullglob
if (( ${#shortcuts[@]} )); then
  for s in "${shortcuts[@]}"; do
    echo "  found: $(basename "$s")"
    (( APPLY )) && rm -f "$s" && echo "    removed"
    (( APPLY )) || echo "    would remove"
  done
else
  echo "  none found — autostart was never set up"
fi

# ---------------------------------------------------------------------------
step "3/5  Undo the registry policies"
# Two policy values were set to get the Windows key out of GlazeWM's way:
#
#   System\DisableLockWorkstation  freed Win+L, so win+l could mean "focus right"
#   Explorer\NoWinKeys             stopped Explorer acting on Win+* combos, which
#                                  is what made the Start menu appear mid-binding
#
# Both live under Policies, which only administrators may write. Run this script
# from an elevated shell or it will tell you the command to run yourself.
# Success is read from the exit code rather than by grepping the output, which
# would be locale-dependent.
policies=(
  'System|DisableLockWorkstation|Win+L locks the workstation again'
  'Explorer|NoWinKeys|the native Win+* shortcuts work again'
)
for entry in "${policies[@]}"; do
  IFS='|' read -r subkey value effect <<<"$entry"
  key="$POLICY_ROOT\\$subkey"
  if "$REG" query "$key" /v "$value" >/dev/null 2>&1; then
    echo "  set: $subkey\\$value"
    if (( APPLY )); then
      if "$REG" delete "$key" /v "$value" /f >/dev/null 2>&1; then
        echo "    deleted — $effect once you sign out and back in"
      else
        echo "    FAILED (needs elevation). Run this in an elevated PowerShell:"
        echo "      reg delete \"$key\" /v $value /f"
      fi
    else
      echo "    would delete it — $effect (needs an elevated shell)"
    fi
  else
    echo "  not set: $subkey\\$value"
  fi
done

# ---------------------------------------------------------------------------
step "4/5  Uninstall the Scoop packages"
# This removes ~/scoop/apps/<app>, the shims and the Start Menu shortcuts. The
# manifests declare no `persist`, so nothing is left behind under ~/scoop.
for app in glazewm zebar; do
  if [[ -d "$WIN/scoop/apps/$app" ]]; then
    echo "  installed: $app"
    run_win "scoop uninstall $app"
  else
    echo "  not installed: $app"
  fi
done

# ---------------------------------------------------------------------------
step "5/5  Remove the config and cache directories"
# None of these belong to Scoop, so `scoop uninstall` leaves every one behind:
#
#   .glzr                        configs, written by both apps on first run
#   AppData\Roaming\zebar        marketplace packs Zebar downloads
#   AppData\Local\com.glzr.zebar WebView2 cache — Zebar is a Tauri app
#
# The canonical GlazeWM config lives in this repo, so nothing unique is lost.
leftovers=(
  "$WIN/.glzr"
  "$WIN/AppData/Roaming/zebar"
  "$WIN/AppData/Local/com.glzr.zebar"
)
for d in "${leftovers[@]}"; do
  if [[ -d $d ]]; then
    echo "  found: ${d#"$WIN"/}  ($(du -sh "$d" 2>/dev/null | cut -f1))"
    if (( APPLY )); then rm -rf "$d" && echo "    removed"; else echo "    would remove"; fi
  else
    echo "  not present: ${d#"$WIN"/}"
  fi
done

# ---------------------------------------------------------------------------
printf '\n'
if (( APPLY )); then
  cat <<EOF
Done. Windows is back to its pre-install state.

Sign out and back in to restore Win+L — the lock policy is read at logon.

Still in the repo, on purpose (remove with git if you want them gone):
  windows/glazewm/          this script and the config
  windows/sync.sh           the GLZR variable and its PAIRS entry
EOF
else
  echo "Dry run finished. Re-run with --apply to perform the steps above."
fi
