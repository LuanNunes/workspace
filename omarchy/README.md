# Omarchy

Setup for the Galaxy Book (Samsung 950XDB) running [Omarchy](https://omarchy.org/)
— Arch Linux with Hyprland on Wayland. Third machine in the repo, and the one
that follows a different rule from the other two.

## The rule here: extend, don't replace

`windows/` snapshots. `macos/` symlinks a machine built from nothing. This
directory does neither, because Omarchy **arrives already configured** — and
configured well. So the repo adds a personal layer on top and leaves the
distro's own choices alone:

| | Omarchy ships | This repo |
|---|---|---|
| Shell | bash + starship + 780 lines of aliases/functions | `~/.bashrc` that **sources** Omarchy's rc, then adds |
| Editor | LazyVim at `~/.config/nvim` | *untouched* — the repo's own Neovim stays on the Mac and WSL |
| Runtimes | mise, from Omarchy's own package repo | `mise-tools.txt` declares which tools; mise owns its config |
| git | `~/.config/git/config` with identity, rerere, histogram diffs | three keys changed, the rest kept |
| Hyprland | defaults in `/usr/share/omarchy/default/hypr/` | the user-override `.lua` files, tracked |
| SSH agent | *nothing* | systemd `ssh-agent.socket` — the one real gap |

The trade is deliberate: uniformity with the other two machines loses to the
distro here, because the distro is the thing that keeps getting updates. A
personal layer that fights `omarchy update` is a layer you re-fix every month.

This is also a **personal** machine — no Domo stack, no GlobalProtect.

## Quick start on a fresh machine

`bootstrap.sh` runs **one step at a time** on purpose — each step prints what it
is about to do and why before doing it.

```sh
git clone git@github.com:LuanNunes/workspace.git ~/Projects/resolverprogramming/workspace
cd ~/Projects/resolverprogramming/workspace

./omarchy/bootstrap.sh --list           # the 7 steps
./omarchy/bootstrap.sh --dry-run all    # print every command, change nothing
./omarchy/bootstrap.sh pkgs             # then run them one by one…
./omarchy/bootstrap.sh all              # …or all of them at once
```

Then open a new terminal, and **log out and back in** once — the `SSH_AUTH_SOCK`
from `~/.config/environment.d/` is read at login, not by a new shell.

Every step is idempotent: re-running one that is already done is a no-op, and any
real file about to be replaced by a symlink is backed up to `<file>.bak.<ts>`.

Afterwards, validate the Hyprland config by hand — nothing checks it until
Hyprland reads it, and a typo at the next login costs you a session:

```sh
hyprctl reload && hyprctl configerrors
```

## Why bash here and zsh on the other two

The other two machines share one `.zshrc`; this one does not, and it is worth
knowing exactly what that buys.

Omarchy ships **no zsh support at all**. `/usr/share/omarchy/default/` has an
`alacritty/`, a `ghostty/`, a `hypr/` and a `bash/` — nothing for zsh. And that
`bash/` directory is not a courtesy, it is 780 lines and a real part of the
distro:

- **~45 aliases and functions** — `n` (nvim), `c`/`cx`/`cy`/`a` (opencode,
  claude, codex, omarchy-agent), `t` (tmux), `h` (herdr), `hdl`/`tdl` (dev pane
  layouts), `ff`/`eff`/`sff` (fzf with a bat preview), `zd` (`cd` through
  zoxide), `rsw`/`lsw`/`dsw` (rsync-on-change watchers), `iso2sd`, and the
  worktree, ssh-reconnect and ssh-port-forwarding helpers
- **tab-completion for the `omarchy` dispatcher** — 129 lines of
  `COMPREPLY`/`compgen`, walking the `omarchy-*` binaries and parsing their
  `# omarchy:args=` headers
- **`EDITOR`/`BROWSER`** wired to `omarchy-launch-editor`/`-browser`, `MANPAGER`
  through bat, mise activation, and the `try` scratch-workspace hook

None of it ports cleanly. The completion has no zsh equivalent to translate into,
and two files (`completions`, `fns/tmux`) index arrays from 0 — which zsh,
indexing from 1, would run **without complaining** and get wrong. A port would
also need re-porting after every `omarchy update`.

So the shell layer here is bash, and `omarchy/bashrc` is Omarchy's stock
`~/.bashrc` with a personal section underneath — which is exactly where the stock
file's own comment invites it. Nothing in that section redefines an Omarchy
alias; it only adds what the distro leaves out (`ll`/`la`, `vim`/`vi`/`v`, `cat`
via bat, `dcu`/`dcd`, atuin).

Before adding an alias there, check you are not shadowing one:

```sh
alias | grep '^alias ll='
```

## mise, and only mise

The Mac and the WSL box pin language runtimes with **asdf** and a shared
`~/.tool-versions`. This machine uses **mise** for everything instead:
`mise-bin` comes from Omarchy's own package repo, Omarchy's bash init runs
`mise activate`, and the `mup` alias updates through it.

Installing asdf alongside would put two shim directories on `PATH` racing over
the same `node`, with the winner decided by load order — and this machine has
already given up shell uniformity, so there is nothing left for that trade to
buy. `doctor` warns if asdf ever shows up.

`mise-tools.txt` is a plain `tool@version` list, applied with `mise use --global`.
The repo declares intent; **mise owns `~/.config/mise/config.toml`**, because
mise rewrites that file itself — see the next section for why symlinking a config
its own tool rewrites is a fight you lose quietly. Same division as
`packages.txt`, which declares intent and lets pacman own its database.

To snapshot this machine back into the repo:

```sh
mise ls --global | awk '{print $1 "@" $2}'
```

## The silent failure mode: `sed -i` and symlinks

Omarchy's update migrations edit user configs in `~/.config`. Most do it in a
symlink-preserving way — `cp` onto the path, or `cat > file`, both of which write
*through* a symlink. But some use `sed -i`, and GNU `sed -i` writes a temp file
and renames it over the target, which **replaces the symlink with a regular
file**. The known targets are the terminal configs (`ghostty`, `foot`,
`alacritty`, `kitty`).

When that happens this machine silently detaches from the repo and keeps working
perfectly — the worst kind of failure, because nothing tells you that `git pull`
stopped reaching Ghostty.

Omarchy is at least aware that dotfiles repos exist: one migration explicitly
declines to rewrite a symlink on the grounds that "a custom link into a dotfiles
repo is a real path even when that repo happens to be unmounted right now." But
that care is not universal, so verify instead of trusting it.

## Taking stock: `bootstrap.sh doctor`

`doctor` writes nothing — it only reads. **Run it after every `omarchy update`.**

```sh
./omarchy/bootstrap.sh doctor
```

It checks every symlink against the repo (catching the `sed -i` detach above),
`OMARCHY_PATH`, every package in `packages.txt`, `ssh-agent.socket`, every tool
in `mise-tools.txt`, whether `~/.bashrc.secrets` still holds template
placeholders, and whether asdf has appeared. Anything it finds is repaired
by re-running the step that owns it, which it tells you.

It also watches for a subtler kind of drift. `omarchy/bashrc` opens with a
**copy** of Omarchy's stock preamble — the three lines that bootstrap
`OMARCHY_PATH`, bail out of non-interactive shells, and source the rc chain — and
a copy goes stale when upstream changes. `/etc/skel/.bashrc` is the original and
is package-owned, so pacman replaces it on update; `doctor` compares our
executable lines against it and names any that went missing. Comments are ignored
on purpose: upstream rewording one is not a problem, upstream adding a `source`
line is.

## Layout

```
omarchy/
├── bootstrap.sh        # one-shot machine setup (idempotent) + `doctor`
├── packages.txt        # every pacman package — official repos and Omarchy's only
├── mise-tools.txt      # the globally-pinned mise tools
├── bashrc              # → ~/.bashrc  (Omarchy's rc + a personal layer)
├── shell.json          # → ~/.config/omarchy/shell.json  (bar layout, idle)
├── ghostty/config      # → ~/.config/ghostty/config
└── hypr/               # → ~/.config/hypr/*.lua
    ├── hyprland.lua        # entrypoint: loads Omarchy defaults, then these
    ├── bindings.lua        # keybinding overrides
    ├── input.lua           # keyboard/touchpad — natural scrolling lives here
    ├── looknfeel.lua       # gaps, borders, animations
    ├── monitors.lua        # displays and scaling
    └── autostart.lua       # extra startup processes
```

The only file this machine takes from the repo root is `.ideavimrc` — it is
IDE-side and has no Omarchy equivalent. `.zshrc`, `.p10k.zsh` and `nvim/` are
not used here.

### Why tracking `hypr/*.lua` is safe

These are *override* files by design. Omarchy loads its own defaults from
`/usr/share/omarchy/default/hypr/` **before** reading them — that is the whole
point of `require("default.hypr.omarchy")` sitting above the `require("hypr.*")`
lines in `hyprland.lua`. Owning them in the repo cannot stop `omarchy update`
from improving the defaults underneath.

Stock, they are almost entirely commented-out examples. Tracking them anyway is
deliberate: it is what makes the desktop reproducible, and the examples are the
documentation for the file, so they are worth keeping.

One side effect, in your favour: a migration that replaces a *stock* config with
a newer default (`replace_with_packaged_config`, which compares a checksum) sees
these as customized and leaves them alone.

## SSH: the one thing Omarchy ships nothing for

There is no agent. `gnome-keyring` runs, but with `--components=pkcs11,secrets` —
its ssh component is gone in current versions, replaced by a separate
`gcr-ssh-agent`. Without an agent, `AddKeysToAgent yes` has nowhere to add the
key and you retype the passphrase on every push.

`bootstrap.sh ssh` enables the `ssh-agent.socket` user unit Arch ships and points
`SSH_AUTH_SOCK` at it from `~/.config/environment.d/`. That is the same shape as
the Mac — the session manager owns the agent, nothing in the shell — and it is
also the only option that reaches GUI programs, since uwsm imports
`environment.d` into the Hyprland session. `keychain`, which the WSL box uses, is
a shell thing and could never do that.

Three machines, three agent stories:

| | Agent | Passphrase |
|---|---|---|
| WSL | `keychain`, driven by `.zshrc` | once per boot, in the first terminal |
| macOS | launchd + `UseKeychain` | once, ever — stored in the login Keychain |
| Omarchy | systemd `ssh-agent.socket` | once per boot, on the terminal that first needs it |

Keys are never generated by the script. Copy `~/.ssh/nunes.lfa` over, `chmod 600`
it, then `ssh -T git@github.com` once.

## Gotchas that cost the most time

| Symptom | Cause |
|---|---|
| `git pull` no longer changes Ghostty | A migration's `sed -i` replaced the symlink. `doctor`, then `links`. |
| An Omarchy alias (`n`, `cx`, `t`…) stopped working | `~/.bashrc` no longer sources `$OMARCHY_PATH/default/bash/rc`. `doctor` compares the whole preamble against `/etc/skel/.bashrc`. |
| Passphrase asked on every push | `ssh-agent.socket` not enabled, or you have not logged out since `bootstrap.sh ssh`. |
| Ctrl-R is plain bash history | atuin needs `bash-preexec` sourced first — bash has no native preexec hook. Both are in `packages.txt`. |
| `claude` or `codex` fails to authenticate | `~/.bashrc.secrets` still exports the `REPLACE_ME` template values, and an invalid `ANTHROPIC_API_KEY` overrides subscription auth. Fill it in or `rm` it; `doctor` flags it. |
| `node --version` disagrees with a project | asdf got installed alongside mise. Pick one; here it is mise. |
| Hyprland comes up unstyled after an edit | A Lua error. `hyprctl configerrors` — always run it after touching `hypr/`. |
| `omarchy` has no tab-completion | You are not in bash. The completion is bash-only, by construction. |

## Keeping it in sync

Like `macos/`, there is no push/pull script — the files are symlinks, so `git
pull` is the whole update. After a pull that touched the lists:

```sh
./omarchy/bootstrap.sh pkgs mise   # install what's new
./omarchy/bootstrap.sh doctor      # and confirm nothing drifted
```

To find packages installed by hand that the repo does not know about:

```sh
comm -13 <(sed -e 's/#.*//' -e '/^\s*$/d' omarchy/packages.txt | sort) \
         <(pacman -Qeq | sort)
```
