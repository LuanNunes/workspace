#!/usr/bin/env bash
# Machine setup, one step at a time.
#
# This script is deliberately NOT a black box. Every step prints WHAT it is
# about to do and WHY before doing it, and each step can be run on its own so
# you can stop, look around, and understand the result before moving on.
#
#   ./macos/bootstrap.sh --list            # the steps, in order
#   ./macos/bootstrap.sh clt               # run one step
#   ./macos/bootstrap.sh brew packages     # run several
#   ./macos/bootstrap.sh all               # run everything, in order
#   ./macos/bootstrap.sh --dry-run all     # print every command, change NOTHING
#
# The long-form explanation of each step — what actually changes on disk, how to
# verify it, and how to undo it — is in ../macos-setup-passo-a-passo.md
#
# Everything is idempotent: re-running a step that is already done is a no-op.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=false

[[ "$(uname -s)" == "Darwin" ]] || { echo "This script is macOS-only."; exit 1; }

STEPS=(clt rosetta brew packages omz links secrets ssh asdf git)

# --- output helpers ---------------------------------------------------------
bold()    { printf '\n\033[1;35m━━ %s\033[0m\n' "$*"; }
explain() { printf '\033[2m%s\033[0m\n' "$*"; }
skip()    { printf '   \033[2m· %s\033[0m\n' "$*"; }
ok()      { printf '   \033[32m✓\033[0m %s\n' "$*"; }

# Echo a command, then run it — unless --dry-run, in which case only echo.
# Everything that MUTATES the machine goes through this, so --dry-run is a
# faithful preview. Read-only probes are called directly.
run() {
  printf '   \033[36m$\033[0m %s\n' "$*"
  $DRY_RUN || "$@"
}
# Same, for anything needing a pipe, redirect or shell expansion.
run_sh() {
  printf '   \033[36m$\033[0m %s\n' "$1"
  $DRY_RUN || eval "$1"
}

# Symlink $1 → $2, moving any real file already there out of the way first.
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    skip "$dst already points at the repo"
    return
  fi
  [[ -d "$(dirname "$dst")" ]] || run mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    run mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  fi
  run ln -sfn "$src" "$dst"
}

# ===========================================================================
step_clt() {
  bold "1/10  Xcode Command Line Tools"
  explain "The compiler toolchain: clang, make, the macOS SDK headers, and Apple's
git. Homebrew needs it to build anything from source, and Neovim's treesitter
needs it to compile parsers. This is the macOS equivalent of build-essential.
Installs to /Library/Developer/CommandLineTools (~1.5 GB)."

  if xcode-select -p >/dev/null 2>&1; then
    skip "already installed at $(xcode-select -p)"
    return
  fi
  run xcode-select --install
  echo
  echo "   A GUI installer opened. Finish it, then re-run this step."
  exit 0
}

# ===========================================================================
step_rosetta() {
  bold "2/10  Rosetta 2"
  explain "Your CPU is arm64. Rosetta translates x86_64 binaries on the fly so
Intel-only software still runs. You mainly need it so OrbStack can run
linux/amd64 container images at usable speed — most work images are still
amd64-only.

Heads up: Apple retires Rosetta in macOS 28 (fall 2027). The narrow exception
Apple is keeping is Intel binaries inside Linux VMs — which is exactly the
container case, so your Docker workflow survives. Intel *Mac apps* will not."

  if /usr/bin/pgrep -q oahd; then
    skip "already installed (oahd translation daemon is running)"
    return
  fi
  run softwareupdate --install-rosetta --agree-to-license
}

# ===========================================================================
step_brew() {
  bold "3/10  Homebrew"
  explain "The package manager — your apt/nala and scoop in one. Two kinds of
package: 'formula' (CLI software, compiled or poured as a prebuilt bottle) and
'cask' (a normal .app dragged into /Applications).

On Apple Silicon the prefix is /opt/homebrew. On Intel Macs it was /usr/local.
Anything you read online that hardcodes /usr/local is Intel-era advice.

'brew shellenv' prints the PATH/MANPATH/HOMEBREW_PREFIX exports for whichever
prefix is installed — .zshrc evals that instead of hardcoding a path, which is
what lets one .zshrc serve this Mac and the WSL box."

  if command -v brew >/dev/null 2>&1; then
    skip "already installed at $(brew --prefix)"
  else
    run_sh '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  fi
  $DRY_RUN || eval "$(/opt/homebrew/bin/brew shellenv)"
}

# ===========================================================================
step_packages() {
  bold "4/10  Packages (brew bundle)"
  explain "Reads macos/Brewfile and installs everything listed. The Brewfile IS
the inventory of this machine — if you install something by hand later, add it
there and commit, or the next machine won't have it.

  brew bundle check --file=macos/Brewfile -v    what's missing
  brew bundle dump  --file=macos/Brewfile --force   snapshot this machine back

Casks download real .app bundles; the first run will ask for your password to
write into /Applications."

  $DRY_RUN || eval "$(/opt/homebrew/bin/brew shellenv)"
  run brew bundle --file="$DOTFILES/macos/Brewfile"

  # Homebrew's completion directory is often group-writable, which makes zsh's
  # compinit refuse to load anything from it and nag on every shell start.
  local sitefun="/opt/homebrew/share/zsh/site-functions"
  if [[ -d "$sitefun" ]]; then
    run chmod -R go-w "/opt/homebrew/share/zsh"
  fi
}

# ===========================================================================
step_omz() {
  bold "5/10  Oh My Zsh"
  explain "macOS already uses zsh as the login shell, so unlike Ubuntu there is
no chsh step. This only installs the Oh My Zsh framework your .zshrc sources.

KEEP_ZSHRC=yes matters: the installer's default behaviour is to overwrite
~/.zshrc with its own template, which would blow away the symlink to the repo."

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    skip "already installed"
    return
  fi
  run_sh 'KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc'
}

# ===========================================================================
step_links() {
  bold "6/10  Dotfile symlinks"
  explain "Each config in the repo is symlinked to where the app expects it, so
editing the repo is live and 'git pull' is the whole update process. Any real
file already at the destination is renamed to <file>.bak.<timestamp> first —
nothing is destroyed.

Note the two config conventions on macOS: CLI tools follow the XDG habit and
read ~/.config/<tool>, while native Mac apps use ~/Library/Application Support.
Ghostty and AeroSpace both accept the ~/.config form, so everything stays in
one place."

  link "$DOTFILES/.zshrc"                          "$HOME/.zshrc"
  link "$DOTFILES/.p10k.zsh"                       "$HOME/.p10k.zsh"
  link "$DOTFILES/.ideavimrc"                      "$HOME/.ideavimrc"
  link "$DOTFILES/nvim/init.lua"                   "$HOME/.config/nvim/init.lua"
  link "$DOTFILES/nvim/lazy-lock.json"             "$HOME/.config/nvim/lazy-lock.json"
  link "$DOTFILES/macos/ghostty/config"            "$HOME/.config/ghostty/config"
  link "$DOTFILES/macos/aerospace/aerospace.toml"  "$HOME/.config/aerospace/aerospace.toml"
}

# ===========================================================================
step_secrets() {
  bold "7/10  Secrets"
  explain "~/.zshrc.secrets holds the API keys. It is git-ignored and sourced by
.zshrc. Copy the real one from the old machine, or fill this template in."

  if [[ -f "$HOME/.zshrc.secrets" ]]; then
    skip "~/.zshrc.secrets exists — not overwriting"
    return
  fi
  run cp "$DOTFILES/.zshrc.secrets.example" "$HOME/.zshrc.secrets"
  run chmod 600 "$HOME/.zshrc.secrets"
  ok "created ~/.zshrc.secrets — fill in the real keys"
}

# ===========================================================================
step_ssh() {
  bold "8/10  SSH config"
  explain "This writes ~/.ssh/config only — it never generates keys. The work key
nunes@domo is registered with the org; regenerating it would lock you out.
Copy the key FILES over from the old machine by hand.

macOS differs from the WSL box here. There, 'keychain' keeps one ssh-agent alive
and you type the passphrase once per boot. Here, AddKeysToAgent + UseKeychain
tell ssh to store the passphrase in the login Keychain and load the key on first
use — so you type it exactly once, ever. That is why the keychain block in
.zshrc is skipped on darwin."

  [[ -d "$HOME/.ssh" ]] || run mkdir -p "$HOME/.ssh"
  run chmod 700 "$HOME/.ssh"

  if [[ -f "$HOME/.ssh/config" ]]; then
    skip "~/.ssh/config exists — not touching it"
  else
    run_sh "cat > '$HOME/.ssh/config' <<'EOF'
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes

# Default GitHub identity: work account (luan-nunes_domo)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/nunes@domo

Host github-luan
    HostName github.com
    User git
    IdentityFile ~/.ssh/nunes.lfa

Host github-domo
    HostName github.com
    User git
    IdentityFile ~/.ssh/nunes@domo

Host orun
    HostName 192.168.50.10
    User root
    IdentityFile ~/.ssh/nunes.lfa
EOF"
    run chmod 600 "$HOME/.ssh/config"
  fi

  echo
  echo "   Once the key files are in ~/.ssh:"
  echo "     chmod 600 ~/.ssh/nunes@domo ~/.ssh/nunes.lfa"
  echo "     ssh-add --apple-use-keychain ~/.ssh/nunes@domo ~/.ssh/nunes.lfa"
  echo "     ssh -T git@github.com && ssh -T git@github-luan"
}

# ===========================================================================
step_asdf() {
  bold "9/10  asdf plugins"
  explain "asdf 0.16+ is a Go binary, not a sourced shell script — .zshrc just puts
its shims directory on PATH. A 'shim' is a tiny wrapper: calling 'node' hits the
shim, which reads .tool-versions and dispatches to the right real binary.

This adds the plugins only. Installing versions is a separate, slow step you
should run yourself so you see what happens:

    asdf install                 # everything in ~/.tool-versions

One warning: python 3.6.2 and 2.7.13 from the old machine will NOT build here.
Both predate Apple Silicon and fail against the modern OpenSSL and the macOS 26
SDK. Pin a current 3.x on this machine; a per-project .tool-versions keeps the
old ones working on the WSL box."

  $DRY_RUN || eval "$(/opt/homebrew/bin/brew shellenv)"
  local plugin
  for plugin in nodejs java golang kotlin dotnet-core python; do
    if asdf plugin list 2>/dev/null | grep -qx "$plugin"; then
      skip "$plugin"
    else
      run asdf plugin add "$plugin" || echo "   could not add $plugin — add it by hand"
    fi
  done

  run mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
  run_sh "asdf completion zsh > '${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf' 2>/dev/null || true"
}

# ===========================================================================
step_git() {
  bold "10/10  git"
  explain "Three machine-level settings:

  core.autocrlf=false   — 'input' was a Windows-era setting. The checkout here is
                          already LF, so no translation is wanted.
  core.excludesfile     — a global ignore file. The Finder writes a .DS_Store into
                          every folder it displays; without this they end up in
                          commits and in colleagues' diffs.
  fetch.prune=true      — delete local refs whose remote branch is gone.

Your identity (user.name/user.email) is NOT set here — copy it from the old
machine or set it per-repo, since you use a work and a personal account."

  run git config --global core.autocrlf false
  run git config --global init.defaultBranch main
  run git config --global fetch.prune true
  run git config --global core.excludesfile "$HOME/.gitignore_global"
  run_sh "printf '.DS_Store\n._*\n.Spotlight-V100\n.Trashes\n' > '$HOME/.gitignore_global'"
}

# ===========================================================================
#  Driver
# ===========================================================================
usage() {
  cat <<EOF
Usage: ./macos/bootstrap.sh [--dry-run] <step>... | all
       ./macos/bootstrap.sh --list

Steps, in order:
   1. clt        Xcode Command Line Tools (compiler, SDK headers)
   2. rosetta    x86_64 translation, for amd64 container images
   3. brew       Homebrew itself
   4. packages   everything in macos/Brewfile
   5. omz        Oh My Zsh framework
   6. links      symlink the repo's configs into place
   7. secrets    create ~/.zshrc.secrets from the template
   8. ssh        write ~/.ssh/config (never generates keys)
   9. asdf       add the language plugins
  10. git        global git settings + .DS_Store ignore

Then, separately:
  ./macos/defaults.sh      system preferences (see the file, it is commented)

Long-form explanation of every step, with how to verify and how to undo:
  macos-setup-passo-a-passo.md
EOF
}

ARGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --list|-l|--help|-h) usage; exit 0 ;;
    *) ARGS+=("$arg") ;;
  esac
done

[[ ${#ARGS[@]} -gt 0 ]] || { usage; exit 0; }

if [[ "${ARGS[0]}" == "all" ]]; then
  ARGS=("${STEPS[@]}")
fi

for want in "${ARGS[@]}"; do
  # shellcheck disable=SC2076
  if [[ ! " ${STEPS[*]} " =~ " ${want} " ]]; then
    echo "Unknown step: $want" >&2
    usage >&2
    exit 1
  fi
done

$DRY_RUN && printf '\n\033[1;33m*** DRY RUN — nothing will be modified ***\033[0m\n'

for want in "${ARGS[@]}"; do
  "step_${want}"
done

bold "Done"
cat <<'EOF'
Steps that are NOT scripted, on purpose — they need your eyes:

  1. ./macos/defaults.sh    system preferences. Read it first; it is commented
                            line by line. Then LOG OUT (key repeat and the
                            Spaces settings are only read at login).

  2. Accessibility permission — System Settings → Privacy & Security →
     Accessibility → add AeroSpace, Raycast, AltTab, Karabiner-Elements.
     macOS shows these apps NO error when the permission is missing; they just
     silently do nothing. It is the #1 "it's broken" on a new Mac.

  3. Copy the SSH keys from the old machine, then ssh-add --apple-use-keychain.

  4. Raycast wants Cmd+Space; let its onboarding disable Spotlight's shortcut.
EOF
