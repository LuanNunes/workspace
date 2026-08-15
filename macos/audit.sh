#!/usr/bin/env bash
# Read-only inventory of what this Mac is actually running.
#
#   ./macos/audit.sh              # everything
#   ./macos/audit.sh dock apps    # only these sections
#   ./macos/audit.sh --list       # section names
#
# This script CHANGES NOTHING. It only reads. It is the "why" that comes before
# the "what" of declutter.sh — decide what to remove from real output, not from
# a blog post's list of `defaults write` lines.
#
# Two commands here may prompt:
#   - `login-items` asks for Automation permission the first time (System Events)
#   - `--sudo` sections read the Background Task Management database
#
# No `set -e`: a section that fails should print its error and let the rest run.
set -uo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "This script is macOS-only."; exit 1; }

SECTIONS=(system managed apps brew login-items agents dock menubar privacy icloud disk)

usage() {
  echo "usage: $0 [--list] [section…]"
  echo "sections: ${SECTIONS[*]}"
}

hdr() { printf '\n\033[1;36m━━ %s %s\033[0m\n' "$1" "$(printf '━%.0s' $(seq $((60 - ${#1}))))"; }
sub() { printf '\n\033[1;33m%s\033[0m\n' "$1"; }
note() { printf '  \033[2m%s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
section_system() {
  hdr "SYSTEM"
  sw_vers
  echo "chip:    $(sysctl -n machdep.cpu.brand_string)"
  echo "memory:  $(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )) GB"
  echo "uptime:  $(uptime)"
}

# ---------------------------------------------------------------------------
# Is this machine yours, or does someone else get a vote? An MDM profile can
# silently re-apply settings you just removed — check this BEFORE fighting a
# setting that keeps coming back.
section_managed() {
  hdr "MANAGEMENT & PROTECTION"

  sub "Configuration profiles (MDM)"
  profiles list 2>/dev/null || note "none, or requires sudo"
  note "'There are no configuration profiles installed' = fully your machine."

  sub "System Integrity Protection"
  csrutil status

  sub "FileVault"
  fdesetup status

  sub "Gatekeeper"
  spctl --status 2>/dev/null

  sub "System extensions (network filters, VPN clients, AV…)"
  systemextensionsctl list 2>/dev/null | grep -v '^$' || note "none"
}

# ---------------------------------------------------------------------------
section_apps() {
  hdr "APPLICATIONS"

  sub "/Applications — DELETABLE (Apple bundles + everything you installed)"
  ls -1 /Applications 2>/dev/null | sed 's/\.app$//'

  sub "~/Applications — user-local, deletable"
  ls -1 "$HOME/Applications" 2>/dev/null | sed 's/\.app$//' || note "empty"

  sub "/System/Applications — SEALED, cannot be deleted, only hidden"
  ls -1 /System/Applications 2>/dev/null | sed 's/\.app$//'
  note "Sealed System Volume. Remove from Dock + exclude from Spotlight instead."

  sub "Installed from the App Store (these re-appear if you sign in elsewhere)"
  find /Applications -maxdepth 3 -name '_MASReceipt' -type d 2>/dev/null \
    | sed -E 's|/Applications/([^/]+)\.app/.*|\1|' || note "none"
}

# ---------------------------------------------------------------------------
# Drift between what the Brewfile declares and what the machine actually has.
section_brew() {
  hdr "HOMEBREW vs Brewfile"
  command -v brew >/dev/null || { note "brew not installed"; return; }

  local bf="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Brewfile"

  sub "Installed but NOT declared in the Brewfile (drift — candidates to remove)"
  brew bundle cleanup --file="$bf" 2>/dev/null || note "nothing to clean"

  sub "Declared but missing (would be installed by \`brew bundle\`)"
  brew bundle check --file="$bf" --verbose 2>/dev/null

  sub "Top-level formulae you asked for (not pulled in as dependencies)"
  brew leaves --installed-on-request 2>/dev/null

  sub "Casks"
  brew list --cask 2>/dev/null

  sub "Disk used by Homebrew"
  du -sh "$(brew --prefix)" 2>/dev/null
}

# ---------------------------------------------------------------------------
# The modern equivalent of Windows' Startup folder is split across three
# places. Most "why is this running?" answers live here.
section_login_items() {
  hdr "LOGIN ITEMS"

  sub "Classic login items (System Settings → General → Login Items)"
  osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null \
    || note "denied or none — grant Automation permission to the terminal to read this"

  sub "Background Task Management — the full picture (needs sudo)"
  if [[ "${AUDIT_SUDO:-0}" == "1" ]]; then
    sudo sfltool dumpbtm 2>/dev/null | grep -E '^\s*(Name|Program|Disposition|Developer):' || note "unavailable"
  else
    note "skipped. Re-run with: AUDIT_SUDO=1 ./macos/audit.sh login-items"
    note "This is where apps hide helpers that survive being 'quit'."
  fi
}

# ---------------------------------------------------------------------------
section_agents() {
  hdr "LAUNCHD AGENTS & DAEMONS (non-Apple only)"

  for dir in "$HOME/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons; do
    sub "$dir"
    ls -1 "$dir" 2>/dev/null | grep -v '^com\.apple\.' || note "empty"
  done

  sub "Currently loaded, third-party"
  launchctl list 2>/dev/null | grep -v -E 'com\.apple\.|^PID' || note "none"
  note "Columns: PID  last-exit-status  label. '-' in PID = loaded but not running."
}

# ---------------------------------------------------------------------------
section_dock() {
  hdr "DOCK"

  sub "Persistent apps, in order"
  defaults read com.apple.dock persistent-apps 2>/dev/null \
    | grep '"file-label"' \
    | sed -E 's/.*= "?([^";]+)"?;.*/  \1/' \
    || note "empty"

  sub "Persistent folders/stacks"
  defaults read com.apple.dock persistent-others 2>/dev/null \
    | grep '"file-label"' \
    | sed -E 's/.*= "?([^";]+)"?;.*/  \1/' \
    || note "empty"

  sub "Relevant settings already applied by defaults.sh"
  for k in autohide tilesize show-recents mru-spaces mineffect; do
    printf '  %-14s %s\n' "$k" "$(defaults read com.apple.dock "$k" 2>/dev/null || echo '(default)')"
  done
}

# ---------------------------------------------------------------------------
# Control Center module visibility. 2 = show in menu bar, 8 = hide,
# 18/24 = show in Control Center only. Values vary by module; read them before
# writing them.
section_menubar() {
  hdr "MENU BAR / CONTROL CENTER"

  sub "com.apple.controlcenter"
  defaults read com.apple.controlcenter 2>/dev/null \
    | grep -E '^\s+"?[A-Za-z]' \
    || note "unset — everything at system default"

  sub "Menu bar extras (legacy NSStatusItem list)"
  defaults read com.apple.systemuiserver menuExtras 2>/dev/null || note "unset"

  sub "Clock"
  defaults read com.apple.menuextra.clock 2>/dev/null || note "default"
}

# ---------------------------------------------------------------------------
section_privacy() {
  hdr "PRIVACY, TELEMETRY & AI"

  sub "Siri / Apple Intelligence"
  printf '  assistant enabled: %s\n' "$(defaults read com.apple.assistant.support 'Assistant Enabled' 2>/dev/null || echo '(default/on)')"
  printf '  Siri in menu bar:  %s\n' "$(defaults read com.apple.Siri StatusMenuVisible 2>/dev/null || echo '(default)')"

  sub "Analytics sent to Apple"
  printf '  AutoSubmit:        %s\n' "$(defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit 2>/dev/null || echo '(unreadable without sudo)')"

  sub "Personalized ads"
  printf '  allowApplePersonalizedAdvertising: %s\n' "$(defaults read com.apple.AdLib allowApplePersonalizedAdvertising 2>/dev/null || echo '(default/on)')"

  sub "Spotlight — what it indexes and suggests"
  defaults read com.apple.Spotlight 2>/dev/null | head -30 || note "default"
  note "Full list is in System Settings → Spotlight; the plist only shows overrides."

  sub "Apps holding sensitive TCC permissions"
  note "Read-only inspection of the TCC DB is blocked by SIP. Check visually:"
  note "System Settings → Privacy & Security → {Accessibility, Full Disk Access, Screen Recording}"
}

# ---------------------------------------------------------------------------
section_icloud() {
  hdr "iCLOUD & CONTINUITY"

  sub "Desktop & Documents syncing to iCloud?"
  if [[ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]]; then
    echo "  iCloud Drive is active"
    [[ -L "$HOME/Desktop" || -L "$HOME/Documents" ]] \
      && echo "  ⚠ Desktop/Documents are REDIRECTED into iCloud" \
      || echo "  Desktop/Documents are local"
  else
    note "iCloud Drive not in use"
  fi

  sub "Handoff / Continuity"
  printf '  Handoff: %s\n' "$(defaults -currentHost read com.apple.coreservices.useractivityd ActivityAdvertisingAllowed 2>/dev/null || echo '(default/on)')"

  sub "Signed-in Apple Account"
  defaults read MobileMeAccounts Accounts 2>/dev/null | grep AccountID || note "not signed in"
}

# ---------------------------------------------------------------------------
section_disk() {
  hdr "DISK"

  sub "Volumes"
  df -h / /System/Volumes/Data 2>/dev/null

  sub "Biggest directories in ~ (top 15)"
  du -sh "$HOME"/* "$HOME"/Library 2>/dev/null | sort -rh | head -15

  sub "Biggest in ~/Library/Application Support (top 10)"
  du -sh "$HOME/Library/Application Support"/* 2>/dev/null | sort -rh | head -10

  sub "Caches"
  # du exits non-zero on the subdirectories SIP keeps us out of, even though it
  # printed a perfectly good total. Without this the section is reported failed.
  du -sh "$HOME/Library/Caches" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
main() {
  local wanted=("$@")
  [[ ${#wanted[@]} -eq 0 ]] && wanted=("${SECTIONS[@]}")

  for s in "${wanted[@]}"; do
    case "$s" in
      --list|-l) usage; return 0 ;;
      --help|-h) usage; return 0 ;;
      *) "section_${s//-/_}" 2>&1 || echo "  (section '$s' failed or does not exist)" ;;
    esac
  done

  printf '\n\033[2mNothing was changed. Paste this output back to decide what goes.\033[0m\n'
}

main "$@"
