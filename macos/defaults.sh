#!/usr/bin/env bash
# macOS system preferences, as code.
#
#   ./macos/defaults.sh
#
# This is the macOS answer to the Windows registry tweaks in
# windows/desktop-customization.md. Everything here is a `defaults write`, which
# is idempotent and reversible — `defaults delete <domain> <key>` restores the
# system default for any single line.
#
# Some settings (key repeat, keyboard access) only take effect after a LOGOUT.
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "This script is macOS-only."; exit 1; }

echo "==> Applying macOS defaults…"

# Keep the sudo timestamp alive for the couple of privileged writes below.
sudo -v

# ===========================================================================
#  Keyboard — the settings that make Vim usable
# ===========================================================================
# macOS ships with a slow repeat and, worse, press-and-hold opens the accent
# picker instead of repeating. Holding `j` in Neovim does nothing until this is
# off. KeyRepeat 2 / InitialKeyRepeat 15 is faster than the GUI slider allows.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Tab moves between every control in dialogs, not just text fields.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Text "helpers" that corrupt code and commit messages.
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ===========================================================================
#  Trackpad & mouse
# ===========================================================================
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Three-finger drag: grab a window/selection by dragging with three fingers
# instead of clicking down. Once it clicks, you won't go back.
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# ===========================================================================
#  Dock & Mission Control
# ===========================================================================
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0        # no hover lag
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock tilesize -int 44
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string "scale"      # cheaper than genie

# Do NOT reorder Spaces by most-recent-use. A tiling WM assumes workspace N
# stays where it is; MRU reordering makes every jump land somewhere random.
defaults write com.apple.dock mru-spaces -bool false

# Don't auto-shuffle windows into Spaces based on the app they belong to.
defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool false

# Hot corners off — they fire constantly while you're aiming for a window edge.
# (0 = no-op; tl/tr/bl/br = top-left, top-right, bottom-left, bottom-right)
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0

# ===========================================================================
#  Finder
# ===========================================================================
defaults write com.apple.finder AppleShowAllFiles -bool true          # dotfiles
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true                # breadcrumb
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # this folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# New windows open in $HOME instead of "Recents".
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Stop littering network shares and USB sticks with .DS_Store files — this is
# what makes your commits and coworkers' zips full of Mac junk.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ===========================================================================
#  Dialogs & animations
# ===========================================================================
# Save/print sheets open expanded instead of the one-line collapsed version.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Window resize/open animations, in seconds. The default feels slow next to a
# tiling WM that repositions windows instantly.
defaults write NSGlobalDomain NSWindowResizeTime -float 0.05
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Save to disk by default, not iCloud Drive.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# ===========================================================================
#  Screenshots
# ===========================================================================
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ===========================================================================
#  Security
# ===========================================================================
# Ask for the password immediately when the screensaver kicks in.
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Touch ID for `sudo` in the terminal. macOS ships a template for exactly this;
# using sudo_local (not /etc/pam.d/sudo) means OS updates won't revert it.
if [[ -f /etc/pam.d/sudo_local.template && ! -f /etc/pam.d/sudo_local ]]; then
  echo "==> Enabling Touch ID for sudo"
  sudo sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
fi

# ===========================================================================
#  Apply
# ===========================================================================
for app in Finder Dock SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

cat <<'EOF'

==> Done.

Two things this script cannot do for you:

  1. LOG OUT and back in. Key repeat, AppleKeyboardUIMode and the Spaces
     settings are read at login — until then Neovim still won't repeat keys.

  2. Grant Accessibility permission, in System Settings → Privacy & Security →
     Accessibility, to: AeroSpace, Raycast, AltTab, Karabiner-Elements.
     macOS gives these apps NO error when the permission is missing — they just
     silently do nothing, which is the single most common "it's broken" on a
     fresh Mac.

EOF
