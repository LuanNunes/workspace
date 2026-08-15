# macOS

Setup for the MacBook Pro (Apple Silicon, macOS Tahoe 26). This directory is the
macOS counterpart of `windows/` — except these files are **symlinked** into
place, not snapshotted, so editing the repo is live.

## Quick start on a fresh machine

`bootstrap.sh` runs **one step at a time** on purpose — each step prints what it
is about to do and why before doing it, so setting the machine up doubles as
learning the OS. The long-form version of each step, with what changes on disk,
how to verify it and how to undo it, is in
[`../macos-setup-passo-a-passo.md`](../macos-setup-passo-a-passo.md).

```sh
git clone git@github-luan:LuanNunes/workspace.git ~/projects/resolveprogramming/workspace
cd ~/projects/resolveprogramming/workspace

./macos/bootstrap.sh --list           # the 10 steps
./macos/bootstrap.sh --dry-run all    # print every command, change nothing
./macos/bootstrap.sh clt              # then run them one by one…
./macos/bootstrap.sh all              # …or all of them at once

./macos/defaults.sh                   # system preferences — read it first, it is
                                      # commented line by line
```

Then **log out and back in** (key repeat and the Spaces settings are read at
login), grant Accessibility permission to AeroSpace/Raycast/AltTab/Karabiner,
and open Ghostty — Zinit and lazy.nvim finish their first-run installs there.

Every step is idempotent: re-running one that is already done is a no-op, and any
real file about to be replaced by a symlink is backed up to `<file>.bak.<ts>`.

### Two things the `packages` step cannot do for you

**Third-party taps need `brew trust` first.** Homebrew now refuses to load a
formula or cask from a tap you have not explicitly trusted — installing runs that
tap's Ruby on your machine, so it wants a decision. `brew bundle` resolves all
packages *before* downloading anything, so one untrusted tap aborts the whole
batch and leaves nothing installed:

```sh
brew trust nikitabobko/tap      # AeroSpace
brew trust felixkratz/formulae  # borders
```

Undo with `brew untrust <tap>`. Same all-or-nothing rule applies to a typo in a
package name — validate the whole Brewfile in one pass before a long run:

```sh
for c in $(grep '^cask ' macos/Brewfile | sed 's/^cask "//; s/".*//'); do
  brew info --cask "$c" >/dev/null 2>&1 || echo "✗ $c"
done
```

**`karabiner-elements` needs a real terminal.** Its `.pkg` installs a DriverKit
keyboard driver as root, and `sudo` refuses to read a password without a TTY — so
it fails under any automation, including an agent's shell. Install it by hand
from Ghostty or Terminal.app:

```sh
brew install --cask karabiner-elements
```

Then approve the system extension in System Settings → Privacy & Security.
Without that approval it installs and silently remaps nothing.

## Taking stock: `audit.sh`

`audit.sh` writes nothing — it only reads. It exists because deciding what to
strip off a Mac from a blog post's list of `defaults write` lines is guesswork;
this prints what *this* machine actually has.

```sh
./macos/audit.sh --list                     # the 11 sections
./macos/audit.sh                            # all of them
./macos/audit.sh managed apps login-items   # the three that matter first
AUDIT_SUDO=1 ./macos/audit.sh login-items   # + the Background Task Management dump
```

Start with `managed`: if a configuration profile (MDM) is installed, some
settings are re-applied behind your back and no amount of `defaults write` will
hold. Know that before fighting one.

### Three layers of clutter, and only two are removable

| Layer | Where | Removable? |
|---|---|---|
| Apple's system apps | `/System/Applications` | **No.** Sealed System Volume (SSV) since Catalina. Not even with SIP disabled — breaking the seal costs you OTA updates. |
| Everything else installed | `/Applications`, `~/Applications` | Yes — `rm -rf`, `brew uninstall`, or drag to Trash |
| Configuration & chrome | Dock, menu bar, Spotlight, Siri, widgets, launchd agents | Yes — `defaults`, `launchctl`, all reversible |

So TV.app and Stocks.app do not leave the disk. They leave the Dock, the
Spotlight index and Launchpad, which is what "clean" actually means here.

The `login-items` and `agents` sections cover what the Windows Startup folder
covers, except macOS splits it across three places: classic login items, the
Background Task Management database (`sfltool dumpbtm`, the one that catches
helpers surviving a Quit), and `LaunchAgents`/`LaunchDaemons` in `~/Library` and
`/Library`.

## Layout

```
macos/
├── bootstrap.sh              # one-shot machine setup (idempotent)
├── defaults.sh               # `defaults write` system prefs — the registry tweaks
├── audit.sh                  # read-only inventory of what the machine runs
├── Brewfile                  # every package, for `brew bundle`
├── ghostty/config            # → ~/.config/ghostty/config
└── aerospace/aerospace.toml  # → ~/.config/aerospace/aerospace.toml
```

Everything else is shared with the WSL box and lives at the repo root:
`.zshrc`, `.p10k.zsh`, `.ideavimrc`, `nvim/`.

## One `.zshrc`, both machines

The same file is symlinked to `~/.zshrc` on WSL and on macOS. Roughly 90 % of it
is identical, so it is not forked; the handful of genuinely platform-specific
blocks sit behind `[[ "$OSTYPE" == darwin* ]]`:

| Block | Linux / WSL | macOS |
|---|---|---|
| SSH agent | `keychain`, loaded before instant prompt | none — `~/.ssh/config` uses `AddKeysToAgent` + `UseKeychain` |
| `DISPLAY` / `LIBGL` | X410 at `0.0.0.0:0` | not set; GUI is native |
| Homebrew prefix | `/home/linuxbrew/.linuxbrew` | `/opt/homebrew` |
| `ANDROID_HOME` | `~/Android/Sdk` | `~/Library/Android/sdk` |
| Keyboard layout | `setxkbmap us intl` | System Settings → Keyboard |
| fastfetch marker | `XDG_RUNTIME_DIR` (tmpfs, wiped on boot) | `$TMPDIR`, mtime compared to `kern.boottime` |
| IDE aliases | `/opt/<ide>/bin/<ide> &` | `open -na "<App Name>"` |

Both branches now resolve Homebrew through `brew shellenv` rather than a
hardcoded path, which also exports `HOMEBREW_PREFIX` — used to put Homebrew's
completions on `fpath` before `compinit`.

`nvim/init.lua` needed no change: its clipboard bridge is already gated on
`vim.fn.has("wsl")`, so on macOS `clipboard=unnamedplus` falls through to the
native `pbcopy`/`pbpaste`. The whole `clip.exe` workaround simply disappears.

## Apple Silicon notes

- **Homebrew is at `/opt/homebrew`**, not `/usr/local` (that prefix is Intel-only
  now). Anything that hardcodes `/usr/local/bin` needs updating.
- **Rosetta 2** is installed by `bootstrap.sh`. It is what lets OrbStack run
  `linux/amd64` images at a usable speed — relevant because most work images are
  still amd64-only. Force a platform with
  `docker run --platform linux/amd64 …` when an image has no arm64 variant.
- **asdf toolchains**: node, java (temurin), go, kotlin and dotnet-core all have
  native arm64 builds and install normally.
- **Python 3.6.2 / 2.7.13 in `~/.tool-versions` will not build here.** Both
  predate Apple Silicon and fail against modern OpenSSL and the macOS 26 SDK.
  Pin a current 3.x on this machine instead — a local `.tool-versions` in each
  project keeps the old versions working on the WSL box.

## Gotchas that cost the most time

| Symptom | Cause |
|---|---|
| AeroSpace / Raycast / AltTab launch but do nothing | Accessibility permission not granted. macOS reports no error. |
| Holding `j` in Neovim doesn't repeat | `ApplePressAndHoldEnabled` — run `defaults.sh`, then **log out**. |
| `Alt-C` (fzf) does nothing in Ghostty | `macos-option-as-alt` — set to `left` in `ghostty/config`. |
| Accents (`á`, `ç`, `ã`) stopped working | Same setting, but set to `true`. Use `left` and type accents with the **right** Option. |
| Windows land on random Spaces | `mru-spaces` still true, or "Displays have separate Spaces" is on. |
| `.DS_Store` in every commit | `core.excludesfile` — written by `bootstrap.sh`. |
| Repos ask for a passphrase every time | Key not in the Keychain: `ssh-add --apple-use-keychain ~/.ssh/<key>`. |

## Keeping it in sync

Unlike `windows/`, there is no push/pull script — the files are symlinks, so
`git pull` is enough. After a pull that touched `Brewfile`:

```sh
brew bundle --file=macos/Brewfile          # install what's new
brew bundle check --file=macos/Brewfile -v # what's missing
brew bundle dump  --file=macos/Brewfile --force  # snapshot this machine back
```
