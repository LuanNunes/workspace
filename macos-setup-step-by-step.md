# 🍎 Guided setup — understanding each step

This document exists because running a script that does ten things at once
teaches you nothing about the new system. Here every step has: **what runs**,
**what actually changes on disk**, **how to verify** and **how to undo**.

Suggested order: read the whole of Part 1 (20 min, worth every minute — it
explains 90 % of the "why does this not work" you are going to hit), then run
Part 2 one step at a time.

**Before anything else, see what would happen without anything happening:**

```sh
./macos/bootstrap.sh --list            # the 10 steps
./macos/bootstrap.sh --dry-run all     # prints every command, changes nothing
```

---

# Part 1 — the 9 concepts that explain macOS

## ① A `.app` is a **folder**, not an executable

```sh
ls -la /Applications/Ghostty.app          # it is a directory
ls /Applications/Ghostty.app/Contents     # MacOS/ Resources/ Info.plist
```

An "app bundle" is a folder that Finder draws as if it were a file. The real
binary is in `Contents/MacOS/`, the metadata in `Info.plist`.

**Practical consequence:** installing is copying a folder, uninstalling is
deleting the folder. There is no "installer" and no entries scattered across a
registry. That is why `brew install --cask` is so fast, and why dragging to the
bin really does uninstall (only preferences in `~/Library` are left, a few KB).

## ② `~/Library` is `AppData`

It is hidden in Finder on purpose. From the terminal it is an ordinary folder:

| Folder | Windows equivalent | Contains |
|---|---|---|
| `~/Library/Preferences/` | registry `HKCU` | the configuration `.plist` files |
| `~/Library/Application Support/` | `%APPDATA%` | app data |
| `~/Library/Caches/` | `%LOCALAPPDATA%\...\Cache` | disposable cache |
| `~/Library/LaunchAgents/` | Startup folder / Run key | what starts at login |
| `~/Library/Logs/` | Event Viewer | app logs |

```sh
open ~/Library          # opens it in Finder even though it is hidden
```

Note the split that causes confusion: **CLI** tools follow the XDG habit and use
`~/.config/<tool>`; **native** apps use `~/Library/Application Support`. Ghostty
and AeroSpace accept both — our symlinks use `~/.config` to keep everything in
one place.

## ③ `defaults` is the registry — and it has a serious catch

```sh
defaults domains                              # every domain (very long)
defaults read com.apple.dock                  # the Dock's current config
defaults read com.apple.dock autohide         # one key
defaults write com.apple.dock autohide -bool true
defaults delete com.apple.dock autohide       # back to the system default
```

That writes to `~/Library/Preferences/com.apple.dock.plist`.

> ⚠️ **Do not edit the `.plist` by hand.** There is a daemon, `cfprefsd`, that
> keeps preferences cached in memory and rewrites the file whenever it feels
> like it — your manual edit is simply lost. `defaults` talks to the daemon; a
> text editor does not. That is the most important difference between `defaults`
> and "editing the registry" on Windows.

Many apps only re-read the config at startup. Hence the `killall Dock` /
`killall Finder` at the end of `defaults.sh` — it is not a hack, it is the right
way.

## ④ `launchd` is `systemd`

A single supervisor for daemons, services and scheduled tasks.

| systemd | launchd |
|---|---|
| `systemctl list-units` | `launchctl list` |
| `systemctl start x` | `launchctl kickstart` / `brew services start x` |
| `/etc/systemd/system/` | `/Library/LaunchDaemons/` (system, at boot) |
| `~/.config/systemd/user/` | `~/Library/LaunchAgents/` (user, at login) |
| cron / timers | also launchd (`StartCalendarInterval`) |

`brew services start postgresql` just writes a `.plist` into
`~/Library/LaunchAgents` and tells launchd. Nothing magic.

## ⑤ SIP — why not even `root` can do everything

**System Integrity Protection** is kernel-level protection: even as root you
cannot write to `/System`, `/usr` (except `/usr/local`), nor inject code into
Apple-signed processes.

```sh
csrutil status        # "System Integrity Protection status: enabled"
```

**Why this matters for your window manager choice:** `yabai` needs to inject
into a system process to get the good features, and for that it asks you to
disable part of SIP. **AeroSpace** was designed to use only the public
Accessibility API — it works with SIP intact. That is why I recommended it, and
not just because it is simpler.

## ⑥ TCC — why the app opens and "does nothing"

**Transparency, Consent and Control** is the permissions database:
Accessibility, Full Disk Access, Input Monitoring, camera, microphone, contacts.

The cultural difference from Windows: UAC **asks and blocks**. TCC frequently
**lets the app run and only denies the capability** — no error, no dialog.
AeroSpace opens, appears in the bar, and simply moves no window at all. Nothing
in the log says why.

```sh
# the database exists, but is protected by SIP — only the UI writes to it
ls -l ~/Library/Application\ Support/com.apple.TCC/
```

Where to fix it: **System Settings → Privacy & Security**.

| Permission | Who needs it here | Without it |
|---|---|---|
| **Accessibility** | AeroSpace, Raycast, AltTab, Karabiner | the app opens and does nothing |
| **Input Monitoring** | Karabiner | keys are not captured |
| **Full Disk Access** | Ghostty/Terminal, backup | `Operation not permitted` in `~/Library`, Mail, etc. |

> If you grant it and it still does not work: **quit and reopen the app**. The
> permission is only read when the process starts.

## ⑦ Gatekeeper, quarantine and notarisation

When a browser downloads a file, it marks it with an extended attribute:

```sh
xattr -l ~/Downloads/something.dmg   # com.apple.quarantine: 0081;...
```

On the first open, Gatekeeper checks the developer signature and
**notarisation** (the app was submitted to Apple, which scanned and stamped it).
Without that: "cannot be opened".

> ⚠️ **The right-click → Open trick was removed in macOS Sequoia** and is still
> removed in Tahoe 26. The current path is:
> **System Settings → Privacy & Security** → scroll to **Security** → **Open
> Anyway**. That button only appears for **about 1 hour** after the blocked
> attempt — if it is gone, try opening the app again and go back there.

From the command line, removing the quarantine mark:

```sh
xattr -d com.apple.quarantine /Applications/App.app
codesign -dv --verbose=4 /Applications/App.app   # who signed it, and with what
spctl -a -vv /Applications/App.app               # what Gatekeeper thinks
```

Apps installed via `brew install --cask` come without quarantine already — brew
removes it.

## ⑧ arm64, x86_64 and Rosetta

```sh
uname -m                          # arm64
arch                              # arm64
file $(which brew)                # Mach-O 64-bit executable arm64
lipo -archs /Applications/Foo.app/Contents/MacOS/Foo   # universal? Intel only?
arch -x86_64 zsh                  # force a translated shell, for testing
```

Rosetta translates Intel binaries on the fly. Two things to know:

1. **Always prefer the native build.** In JetBrains Toolbox, choose "Apple
   Silicon", not Intel.
2. **Apple retires Rosetta in macOS 28 (autumn 2027).** The exception it will
   keep is precisely Intel binaries **inside Linux VMs** — which is the case of
   OrbStack running a `linux/amd64` image. Your container workflow survives;
   native Intel apps stop.

## ⑨ APFS is *case-insensitive* by default

```sh
diskutil info / | grep -i "File System"
```

`File.ts` and `file.ts` are the **same file**. A repo coming from Linux that
contains both will behave strangely in `git status`. If you hit that, create a
separate case-sensitive APFS volume (Disk Utility → `+`) and clone the project
there.

### Bonus: why your `PATH` looks scrambled

macOS runs `/usr/libexec/path_helper` from `/etc/zprofile`, which **rebuilds**
the `PATH` from `/etc/paths` and `/etc/paths.d/*`. That happens **before**
`~/.zshrc`. Which is why `.zshrc` does `eval "$(brew shellenv)"` — to put
Homebrew in front **after** path_helper has done its thing.

```sh
cat /etc/paths; ls /etc/paths.d/
echo $PATH | tr ':' '\n'
```

---

# Part 2 — the 10 steps

Each one runs on its own: `./macos/bootstrap.sh <step>`.

---

## Step 1 — `clt` · Xcode Command Line Tools

```sh
./macos/bootstrap.sh clt
```

**What it is:** clang, make, the macOS SDK headers and Apple's git. The
`build-essential` of this world. Homebrew needs it to compile, and Neovim's
treesitter to compile parsers.

**What changes:** ~1.5 GB in `/Library/Developer/CommandLineTools`. It opens a
graphical installer — that is normal, it cannot be automated without
downloading from the portal.

**Verify:**
```sh
xcode-select -p          # /Library/Developer/CommandLineTools
clang --version
```

**Undo:** `sudo rm -rf /Library/Developer/CommandLineTools`

---

## Step 2 — `rosetta`

```sh
./macos/bootstrap.sh rosetta
```

**What it is:** the x86_64 → arm64 translator (concept ⑧).

**What changes:** installs the `oahd` translation daemon. Nothing in your
`$HOME`.

**Verify:**
```sh
pgrep oahd && echo "rosetta active"
arch -x86_64 uname -m     # prints x86_64 = translation working
```

**Undo:** `sudo softwareupdate --install-rosetta` has no official removal
counterpart; in practice it is not worth uninstalling.

---

## Step 3 — `brew` · Homebrew

```sh
./macos/bootstrap.sh brew
```

**What it is:** the package manager. **Formula** = CLI software (compiled, or
downloaded ready-made as a "bottle"). **Cask** = an ordinary `.app` copied into
`/Applications`.

**What changes:** creates `/opt/homebrew` (on Apple Silicon; `/usr/local` is
Intel, and any tutorial using that path is from the Intel era). It asks for your
password once to create the directory.

**Verify:**
```sh
brew --prefix            # /opt/homebrew
brew config
/opt/homebrew/bin/brew shellenv     # see exactly what .zshrc evaluates
```

**Undo:** Homebrew's official uninstall script, or `sudo rm -rf /opt/homebrew`.

---

## Step 4 — `packages` · everything from the Brewfile

```sh
./macos/bootstrap.sh packages     # slow; it is the longest step
```

**What it is:** reads `macos/Brewfile` and installs everything. That file **is**
the machine's inventory — installed something by hand afterwards? Add it there
and commit.

**What changes:** binaries in `/opt/homebrew/bin`, apps in `/Applications`. It
will ask for a password for the casks.

**Verify:**
```sh
brew bundle check --file=macos/Brewfile --verbose    # what is missing
brew list --formula | wc -l
brew list --cask
```

**Undo:** `brew uninstall <package>` or
`brew bundle cleanup --file=macos/Brewfile`.

> The step also runs `chmod -R go-w /opt/homebrew/share/zsh`. Without it, zsh's
> `compinit` detects the directory as group-writable, refuses to load the
> completions from there and complains on every shell you open.

---

## Step 5 — `omz` · Oh My Zsh

```sh
./macos/bootstrap.sh omz
```

**What it is:** just the framework your `.zshrc` already sources. There is **no**
`chsh` here: macOS has used zsh as the login shell since Catalina.

**What changes:** `~/.oh-my-zsh`. `KEEP_ZSHRC=yes` is essential — without it the
installer overwrites `~/.zshrc` with its own template, destroying the symlink.

**Verify:** `ls ~/.oh-my-zsh && echo $SHELL` → `/bin/zsh`

**Undo:** `uninstall_oh_my_zsh` or `rm -rf ~/.oh-my-zsh`.

---

## Step 6 — `links` · the symlinks

```sh
./macos/bootstrap.sh --dry-run links    # see the destinations first
./macos/bootstrap.sh links
```

**What changes:**

| Destination | Source in the repo |
|---|---|
| `~/.zshrc` | `.zshrc` |
| `~/.p10k.zsh` | `.p10k.zsh` |
| `~/.ideavimrc` | `.ideavimrc` |
| `~/.config/nvim/init.lua` | `nvim/init.lua` |
| `~/.config/nvim/lazy-lock.json` | `nvim/lazy-lock.json` |
| `~/.config/ghostty/config` | `macos/ghostty/config` |
| `~/.config/aerospace/aerospace.toml` | `macos/aerospace/aerospace.toml` |

If a **real** file already exists at the destination, it is renamed to
`<file>.bak.<timestamp>` — nothing is destroyed.

**Verify:** `ls -la ~/.zshrc` → should show `-> .../workspace/.zshrc`

**Undo:** `rm ~/.zshrc && mv ~/.zshrc.bak.<ts> ~/.zshrc`

---

## Step 7 — `secrets`

```sh
./macos/bootstrap.sh secrets
```

Creates `~/.zshrc.secrets` (chmod 600) from the template. It is git-ignored and
sourced by `.zshrc`. If you copied the real file from the old machine, the step
detects it and does not overwrite.

**Verify:** `ls -l ~/.zshrc.secrets` → `-rw-------`

---

## Step 8 — `ssh`

```sh
./macos/bootstrap.sh ssh
```

**What it does:** writes **only** `~/.ssh/config`. It **never generates keys** —
`nunes@domo` is registered with the org, and regenerating locks you out.

**The conceptual difference from WSL:** there, `keychain` keeps an `ssh-agent`
alive and you type the passphrase once per boot. Here, `AddKeysToAgent yes` +
`UseKeychain yes` tell ssh to store the passphrase in macOS's **login Keychain**
and load the key on demand — you type it **once, and never again**. That is why
the `keychain` block in `.zshrc` is skipped on darwin.

**After copying the key files:**
```sh
chmod 600 ~/.ssh/nunes@domo ~/.ssh/nunes.lfa
ssh-add --apple-use-keychain ~/.ssh/nunes@domo ~/.ssh/nunes.lfa
ssh-add -l                       # what is loaded
ssh -T git@github.com            # should greet luan-nunes_domo
ssh -T git@github-luan           # should greet LuanNunes
```

**To check where the passphrase ended up:** open the **Keychain Access** app and
search for `SSH`. It is there, encrypted by the login.

---

## Step 9 — `asdf`

```sh
./macos/bootstrap.sh asdf
```

**What it does:** only adds the plugins (nodejs, java, golang, kotlin,
dotnet-core, python) and generates the completions. It **does not install
versions** — that is slow and you should watch it happen:

```sh
asdf install            # everything in ~/.tool-versions
asdf list               # what is installed
asdf current            # what is active here
```

**How asdf works:** it does not swap the `PATH` per project. It puts a **shims**
directory on the PATH — each shim is a tiny wrapper that reads the nearest
`.tool-versions` and dispatches to the real binary. That is why `.zshrc` only
needs one PATH line.

> ⚠️ **`python 3.6.2` and `2.7.13` from your `~/.tool-versions` do not compile
> here.** They predate Apple Silicon and break against OpenSSL 3 and the macOS
> 26 SDK. Pin a current 3.x on this machine; a per-project `.tool-versions`
> keeps the old versions working on WSL.

---

## Step 10 — `git`

```sh
./macos/bootstrap.sh git
```

Three machine-level settings: `core.autocrlf=false` (`input` was a Windows-era
thing), `fetch.prune=true`, and a `~/.gitignore_global` with `.DS_Store` —
because Finder creates that file in **every** folder it displays, and without
this they leak into your commits.

**Your identity is not configured here**, on purpose — you use two accounts.

```sh
git config --global --list           # see everything
git config --show-origin --get user.email    # find out which file it came from
```

---

# Part 3 — `defaults.sh`, and why a logout

```sh
./macos/defaults.sh
```

**Read the file before running it** — it is commented line by line, and now that
you understand concept ③ every line makes sense. Groups:

| Group | Highlight |
|---|---|
| Keyboard | `ApplePressAndHoldEnabled=false` — **without it, holding `j` in Neovim does not repeat**, it opens the accent picker |
| Trackpad | tap-to-click and three-finger drag |
| Dock / Spaces | `mru-spaces=false` — without it macOS reorders Spaces by usage and AeroSpace becomes unpredictable |
| Finder | hidden files, path bar, folders sorted first |
| Screenshots | go to `~/Pictures/Screenshots` instead of the Desktop |
| Security | Touch ID for `sudo` |

**Why a logout and not just `killall`:** `KeyRepeat`, `InitialKeyRepeat` and
`AppleKeyboardUIMode` are read by `WindowServer` when the **login session** is
created. `killall` on an app does not reload those.

**Touch ID for sudo** deserves an explanation: we write to
`/etc/pam.d/sudo_local`, not `/etc/pam.d/sudo`. Apple created that file
precisely for customisation — it **survives system updates**, while edits to
`sudo` are reverted on every update.

**To undo any line:**
```sh
defaults delete <domain> <key>          # back to the system default
defaults read com.apple.dock            # check the current state
```

---

# Part 4 — investigation toolbox

When something does not work, these commands answer on their own:

```sh
# --- system ---
sw_vers                                   # macOS version
system_profiler SPHardwareDataType        # chip, RAM, serial
csrutil status                            # SIP on?
pmset -g                                  # power/battery
diskutil list                             # APFS volumes

# --- apps ---
lsappinfo list                            # what is running, with PID and bundle id
osascript -e 'id of app "Ghostty"'        # find an app's bundle id
codesign -dv --verbose=4 /Applications/X.app   # signature
xattr -l /Applications/X.app              # quarantined?
mdfind -name "something"                  # Spotlight search from the CLI

# --- config ---
defaults domains | tr ',' '\n' | sort     # every domain
defaults read com.apple.dock              # an app's config
defaults read-type com.apple.dock autohide

# --- services ---
launchctl list | grep -i homebrew
brew services list
ls ~/Library/LaunchAgents/

# --- logs (the Event Viewer of this world) ---
log show --last 5m --predicate 'process == "AeroSpace"'
log stream --predicate 'eventMessage CONTAINS "denied"'   # live

# --- network ---
networksetup -listallhardwareports
scutil --dns
```

`log show`/`log stream` is the biggest time-saver: TCC records its denials
there. If an app "does nothing", `log stream` with `denied` usually shows
exactly which permission is missing.

---

# Suggested route, unhurried

| When | What |
|---|---|
| Day 1 | Read Part 1. `--dry-run all`. Steps 1–5. |
| Day 1 (evening) | Steps 6–10. Open Ghostty, let Zinit and lazy.nvim install. |
| Day 2 | Read and run `defaults.sh`. Log out. Grant Accessibility. |
| Day 2 | Copy the SSH keys, validate both remotes. |
| Day 3 | `asdf install`, bring up a real project, see what is missing. |
| Week 2 | Only then turn AeroSpace on for real (`macos-cheatsheet.md` §6). |

Day-to-day reference — shortcuts, accents, Windows→macOS equivalents:
**[`macos-cheatsheet.md`](macos-cheatsheet.md)**.
