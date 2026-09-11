# 🍎 macOS Cheat-Sheet (Windows + WSL → MacBook Pro transition)

First Apple machine. Same rule as Vim and the shell: **one new thing per week**,
not all of them today. The 4-week plan is at the end.

---

## 0. Before installing anything

Own machine, own control — no MDM. The order that makes sense is: **Software
Update → Apple Account → FileVault → Time Machine**, and only then the dev
environment.

FileVault first because turning it on while the disk is still empty is
instantaneous; after 500 GB of projects, the initial encryption takes hours
running in the background.

> Want to understand what each setup step does before running it?
> **[`macos-setup-step-by-step.md`](macos-setup-step-by-step.md)** — system
> concepts, and every step with "what changes / how to verify / how to undo".

### What to bring from the old machine (Homebrew reinstalls none of this)

| Source (WSL) | Destination (Mac) | Why |
|---|---|---|
| `~/.ssh/nunes@domo{,.pub}` | `~/.ssh/` | work key, registered with Domo — **never** regenerate |
| `~/.ssh/nunes.lfa{,.pub}` | `~/.ssh/` | personal key (GitHub `github-luan`) |
| `~/.zshrc.secrets` | `~/.zshrc.secrets` | `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` |
| `~/.gnupg/` | `~/.gnupg/` | GPG keys (losing them = losing old signatures) |
| `~/.kube/config` | `~/.kube/config` | cluster contexts |
| `~/.aws/{config,credentials}` | `~/.aws/` | the EKS access `tug` uses |
| `~/.m2/settings.xml` | `~/.m2/` | internal Maven repositories/credentials |
| `~/.gradle/gradle.properties` | `~/.gradle/` | same for Gradle |
| `~/.npmrc`, `~/.nuget/NuGet/NuGet.Config` | same | private registries |
| `atuin` sync key | — | `atuin key` on the old machine, save it beforehand |
| `~/projects/` | `~/projects/` | or just re-clone everything, if it is all pushed |

```sh
# from the old machine, with the Mac already on the network:
scp ~/.ssh/nunes@domo ~/.ssh/nunes@domo.pub ~/.ssh/nunes.lfa ~/.ssh/nunes.lfa.pub \
    ~/.zshrc.secrets <mac>:~/
```

Afterwards: `chmod 600` on the keys and
`ssh-add --apple-use-keychain ~/.ssh/nunes@domo`.

> There is an official **Windows Migration Assistant**, but for a dev machine it
> brings junk and none of the files above. Use the list.

---

## 1. The three ideas that unlock everything

### ① Cmd is the new Ctrl — and that is a gift

On Windows, `Ctrl+C` is *copy* **and** *kill process*. That conflict is why the
Windows terminal has odd shortcuts. On the Mac:

```
   Cmd+C  → copy            (application level)
   Ctrl+C → SIGINT          (terminal level)
```

They are **different** keys. Vim and zsh get almost all of `Ctrl` back:
`Ctrl+R` (atuin), `Ctrl+T` (fzf), `Ctrl+A/E` — free, no conflict. The exception
is `Ctrl+W`, which since 2026-09-10 closes a window in AeroSpace (section 6) and
therefore no longer reaches zsh or Neovim.

### ② App ≠ window

The biggest trap for someone coming from Windows:

| You want to | Windows | macOS |
|---|---|---|
| close the **window** | `Alt+F4` | `Cmd+W` — **the app keeps running** |
| close the **app** | `Alt+F4` | `Cmd+Q` |
| switch **app** | `Alt+Tab` | `Cmd+Tab` |
| switch **window of the same app** | `Alt+Tab` | `` Cmd+` `` |

The menu bar at the top belongs to the **focused app**, not to the window. That
is why it changes when you switch apps.

> **`Alt+Tab` is AltTab**, which is a per-**window** switcher — picking one
> brings that window up. `Cmd+Tab` is still the native, per-**app** one, and it
> is where "I picked the app and nothing opened" comes from: activating an app
> raises no window at all.
>
> AeroSpace maps **nothing** to `Alt+Tab` or `Alt+Shift+Tab`, deliberately:
> those two are AltTab's default shortcuts, and AeroSpace grabs them before the
> app does, so any binding there would eat the switcher. That is exactly what
> used to happen — `Alt+Tab` was `workspace-back-and-forth` and changed
> workspace when you wanted to change app. That command went with it; if it is
> missed, give it a chord that is not tab.
>
> It needs **Accessibility** to see other apps' windows, and **Screen & System
> Audio Recording** to show title and thumbnail (the alarming name is Sequoia's,
> which folded system audio into the same switch). Without the first it opens
> and does nothing.
>
> `Alt` + `` ` `` is still the cycle within **this** workspace (section 6) —
> AltTab lists everything, with no workspace filter, and the two serve different
> moments.
>
> ⚠️ **That "lists everything" is a SETTING, and the wrong value looks exactly
> like a broken switcher.** AltTab → Settings → Windows has *Show windows from:*
> **All screens** / **All spaces**; set to *Active screen*, it lists only the
> windows on the monitor you are focused on, and the browsers on the primary
> screen simply never appear while you are typing on the side one. Diagnosed on
> 2026-09-11 as "`Alt+Tab` stopped opening Chrome". `macos/defaults.sh` now
> writes both back to *all*:
>
> ```sh
> defaults read com.lwouis.alt-tab-macos | grep -E 'screensToShow|spacesToShow'
> ```
>
> Both must read `0`. AltTab writes its own preferences **when it quits**, so a
> `defaults write` against a running AltTab is erased the next time it exits —
> quit it first, write, then relaunch.

> **One thing tried and undone, so it is not repeated:** remapping `Cmd+Tab` in
> **Karabiner** to AeroSpace's cycle. It works, but Karabiner intercepts at the
> HID level, so macOS never sees the key and the overlay with the icons
> **disappears**. The switch becomes a blind jump. Undone the same day.

### ③ Underneath it is BSD, not Linux

The utilities are BSD's, with different flags:

```sh
sed -i 's/a/b/' f     # ✅ Linux    ❌ macOS (wants a backup suffix)
sed -i '' 's/a/b/' f  # ✅ macOS
ls --color            # ❌ macOS
date -d '1 day ago'   # ❌ macOS
```

That is why the `Brewfile` installs `coreutils`, `gnu-sed`, `gawk`, `grep` —
which become `gls`, `gsed`, `gawk`, `ggrep`. They do **not** go to the front of
the PATH, on purpose: a script assuming BSD would break. Call them with the
leading `g` when you need Linux behaviour.

---

## 2. Shortcut conversion table

| Action | Windows | macOS |
|---|---|---|
| Copy / paste / cut | `Ctrl+C/V/X` | `Cmd+C/V/X` |
| Paste **moving** a file | `Ctrl+X` → `Ctrl+V` | `Cmd+C` → `Cmd+Option+V` |
| Undo / redo | `Ctrl+Z` / `Ctrl+Y` | `Cmd+Z` / `Cmd+Shift+Z` |
| Save / open / print | `Ctrl+S/O/P` | `Cmd+S/O/P` |
| Select all | `Ctrl+A` | `Cmd+A` |
| Find / next | `Ctrl+F` / `F3` | `Cmd+F` / `Cmd+G` |
| New tab / close tab | `Ctrl+T` / `Ctrl+W` | `Cmd+T` / `Cmd+W` |
| Reopen closed tab | `Ctrl+Shift+T` | `Cmd+Shift+T` |
| **Start / end of line** | `Home` / `End` | `Cmd+←` / `Cmd+→` |
| **Start / end of document** | `Ctrl+Home/End` | `Cmd+↑` / `Cmd+↓` |
| Word by word | `Ctrl+←/→` | `Option+←/→` |
| **Forward delete** | `Delete` | `Fn+Delete` |
| Rename file | `F2` | `Enter` (!) |
| Open file | `Enter` | `Cmd+↓` or `Cmd+O` |
| Properties / info | `Alt+Enter` | `Cmd+I` |
| Delete file | `Delete` | `Cmd+Delete` |
| Task manager | `Ctrl+Shift+Esc` | `Cmd+Option+Esc` (Force Quit) |
| Lock screen | `Win+L` | `Ctrl+Cmd+Q` |
| Launcher | `Win` / Flow Launcher | `Cmd+Space` (Raycast) |
| Clipboard history | Ditto | `Cmd+Shift+V` (Maccy) |
| Screenshot (region) | `Win+Shift+S` | `Cmd+Shift+4` |
| Screenshot (screen) | `PrtScr` | `Cmd+Shift+3` |
| Screen recording / options | Xbox Game Bar | `Cmd+Shift+5` |
| Emoji | `Win+.` | `Fn+E` or `Ctrl+Cmd+Space` |
| Minimise / hide app | `Win+D` | `Cmd+M` / `Cmd+H` |
| Space/desktop next door | `Ctrl+Win+←/→` | `Ctrl+←/→` |
| Mission Control | `Win+Tab` | `Ctrl+↑` (or 3 fingers up) |
| Force reload without cache | `Ctrl+F5` | `Cmd+Shift+R` |

**Inside Ghostty/Neovim/zsh, `Ctrl` is still `Ctrl`.** Nothing above interferes
with your Vim muscle memory.

---

## 3. Keyboard

### Portuguese accents

Ghostty is configured with `macos-option-as-alt = left`. That means:

- **Left Option** = a real `Alt` → fzf's `Alt+C`, readline's `Alt+B/F`.
- **Right Option** = dead key for composition → accents:

| You want | Type |
|---|---|
| á é í ó ú | `⌥e` then the vowel |
| ã õ ñ | `⌥n` then the vowel |
| â ê ô | `⌥i` then the vowel |
| ç | `⌥c` |
| à | `⌥\`` then `a` |
| ü | `⌥u` then `u` |

> **`acentos`** in the terminal prints that table. It is a function in `.zshrc`
> (macOS only), so you do not have to come back here every time the dead key
> slips your mind.

If you prefer a dedicated keyboard layout, System Settings → Keyboard → Input
Sources → **ABC – Extended** (better for dev, keeps the US layout) or
**Brazilian**.

### Settings worth making on day one

| Setting | Where |
|---|---|
| **Caps Lock → Esc** (pure gold in Vim) | `macos/karabiner/karabiner.json` — applies to **every** keyboard |
| F1–F12 as function keys, not brightness/volume | same, but only on the Keychron K2 |
| Fast key repeat | already done by `defaults.sh` — requires a **logout** |
| 🌐 (Globe) key doing nothing | Keyboard → Press 🌐 to → Do Nothing |

### Keychron K2

The `Caps Lock` setting in System Settings → Keyboard → Keyboard Shortcuts →
Modifier Keys is **per device**: set on the K2, it does not apply to the
built-in keyboard, and it disappears when you plug in another one. That is why
the remap lives in Karabiner, versioned in the repo.

The K2 in Mac mode announces itself with **Apple**'s vendor ID (`1452`), product
`591` — the built-in keyboard is `1452`/`33028`, so the two are
distinguishable. That pair is what `karabiner.json` uses to make the fn row
F1–F12 on the K2 only, keeping brightness/volume direct on the MacBook's own
keyboard.

#### `Page Down` becomes `Del` (forward delete)

macOS calls `delete` the key that erases **backwards** — Windows' Backspace.
Erasing forwards (`⌦`, Windows' `Del`) is `Fn`+`delete`, a chord for something
that was a single key on Windows.

`karabiner.json` remaps `page_down` → `delete_forward`, **on the K2 only**. You
do not lose the page function: `Fn`+`↓` is native Page Down on macOS, with no
configuration at all.

To identify any key on this keyboard with certainty — the legends are doubled
and change role with the side switch — open **Karabiner-EventViewer** and press
the key. It shows the name macOS received (`delete_or_backspace` for Backspace,
`delete_forward` for Del).

#### The bottom row changes order with the side switch

This is trap number 1 for anyone coming from Windows, and it **looks** like a
config bug: "Alt stopped working".

```
Windows/Android:   Ctrl │  ⊞ Win   │   Alt     │ ␣
Mac/iOS:           Ctrl │ ⌥ Option │ ⌘ Command │ ␣
```

The key next to the space bar used to be `Alt` and is now `⌘ Command`. The
finger goes to the same place and the wrong modifier comes out, so no AeroSpace
`alt-*` binding fires. Option is **one key to the left**.

A 5-second test, with no tooling at all: in Spotlight, type something, hold the
suspect key and press `A`. Selected everything = it is `Command`. Produced `å` =
it is `Option`.

Swapping Option↔Command to "give" Alt back to the thumb is not worth it: `⌘` is
the most-used key on macOS, and the remap would apply only to the K2 — the
built-in keyboard would stay on the Apple layout, leaving the two muscle
memories in conflict.

Two physical prerequisites, before blaming the config:

1. The K2's side switch on **Mac/iOS**, not Windows/Android.
2. Karabiner needs its **driver extension** approved. Without it, it sits
   installed and inert, with no error message at all:

```sh
systemextensionsctl list      # "0 extension(s)" = inert
```

Approve it in System Settings → General → Login Items & Extensions → Driver
Extensions, and grant Input Monitoring in Privacy & Security.

> `defaults.sh` turns off `ApplePressAndHoldEnabled`. Without that, **holding
> `j` in Neovim does not repeat** — it opens the accent picker. It is the number
> 1 frustration for Vim users on the Mac.

---

## 4. Trackpad — what you will miss if you go back

Worth investing 10 minutes here. System Settings → Trackpad.

| Gesture | Does |
|---|---|
| 3 fingers up | Mission Control (all windows) |
| 3 fingers sideways | switch Space / full screen |
| 4 fingers pinching | Launchpad |
| Spread 4 fingers | show Desktop |
| 2 fingers at the edges | scroll (natural, inverted — can be turned off) |
| **3 fingers dragging** | move a window/selection without clicking |

`defaults.sh` already turns on **tap to click** and **three-finger drag** (the
second one is hidden under Accessibility in the UI).

> An external mouse with inverted scrolling is the classic: macOS applies
> "natural scrolling" to the trackpad **and** the mouse from the same switch.
> **LinearMouse** (already in the Brewfile, config versioned in
> `macos/linearmouse/`) separates the two.

### Mouse speed: one device, one place

| Device | Where to set it |
|---|---|
| External mouse (Keychron M2) | LinearMouse → *Pointer → Speed* |
| Trackpad | System Settings → Trackpad |

`linearmouse.json` turns off the M2's acceleration (`disableAcceleration`). With
it off, LinearMouse governs that device's pointer and macOS's curve steps out of
the way — so moving *Tracking speed* in System Settings changes almost nothing,
and the mouse feels broken. Set the speed in the same place the acceleration is
turned off.

The system's `com.apple.mouse.scaling` still applies as a **fallback**, for the
window before login items load or if LinearMouse dies. Leave it at a sane value
— set to an extreme, that window feels like a fault.

---

> **"Notifications" on the desktop that will not close** are probably not
> notifications. Desktop widgets (Stocks, Weather, Calendar) are drawn by the
> *Notification Center* process and sit on a **negative** layer, behind
> everything — hence no close button. To identify one, the owner and the layer
> show up in any window inspector; negative layer = widget.
>
> `defaults.sh` already turns off both switches (`StandardHideWidgets` and
> `StageManagerHideWidgets`). To remove only some instead of all, it is
> Control-click on the desktop → *Edit Widgets*, and the minus on each one.

### A notification stuck on screen

A banner that will not leave on the X or on hover:

```sh
killall NotificationCenter
```

The agent restarts by itself — it belongs to the system — and the on-screen
banners go away. It does not erase Notification Center history, it only clears
what is drawn.

> ⚠️ **Answer before killing.** Some banners are requests for a decision, not
> notices: *App Background Activity* ones (agents and daemons asking to start at
> login) and notification-permission ones have `Allow` / `Don't Allow` appearing
> on hover. Dismissing without answering leaves the request pending — and in the
> case of Karabiner's daemons, that means the remap stops working on the next
> boot, with no error at all.
>
> A purely informative notice, like *"Login Item Added"*, you can kill freely.

If the banner does **not** respond to `killall`, it is probably not a
notification: see the note about desktop widgets above.

---

## 5. Finder vs Explorer

| Explorer | Finder |
|---|---|
| address bar | `Cmd+Shift+G` → type the path |
| `Ctrl+X` on a file | does not exist — `Cmd+C` then `Cmd+Option+V` |
| show hidden | `Cmd+Shift+.` |
| new folder | `Cmd+Shift+N` |
| go up one level | `Cmd+↑` |
| back | `Cmd+[` |
| open terminal here | right-click → Services, or `open .` in the other direction |
| space = nothing | **space = Quick Look** (preview of any file) |

From the terminal, `open .` opens Finder in the current folder — WSL's
`explorer.exe .`.

**`.DS_Store`**: Finder creates that file in every folder you open.
`bootstrap.sh` puts it in a `~/.gitignore_global` so it does not leak into a
commit.

---

## 6. Windows — AeroSpace

i3-like tiling, without touching SIP. Config in
`macos/aerospace/aerospace.toml`. Here `alt` = **Option**.

| Shortcut | Action |
|---|---|
| `Alt+Shift+Enter` | focus Ghostty (opens one if there is none) |
| `Alt+H/L` | move **focus** horizontally — crosses monitors |
| `Alt+J/K` | move **focus** vertically — **stays** in this workspace |
| `Alt+Shift+H/L` / `Alt+Shift+J/K` | move the **window**, same boundaries |
| `Alt+A` | back to the previous window (within the same workspace) |
| `Alt` + `` ` `` | **next** window in this workspace |
| `Alt+Shift` + `` ` `` | the previous one, same ring the other way |
| `Alt+1/2/3` | switch **all three monitors** at once (desktop 1/2/3) |
| `Alt+4..9` | move **one** screen only (breaks the trio on purpose) |
| `Alt+Shift+1..9` | send a window to a workspace |
| `Alt+Ctrl+1/2/3` | send a window to another **desktop**, same column |
| `Alt+Tab` / `Alt+Shift+Tab` | **AltTab**, not AeroSpace — see above |
| `Alt+Ctrl+H/J/K/L` | move **focus** between monitors |
| `Alt+Ctrl+Shift+H/J/K/L` | send the window to another **monitor** |
| `Alt+/` | toggle horizontal/vertical split |
| `Alt+,` | switch to accordion (stack them) |
| `Alt+F` | fullscreen |
| `Alt+Shift+F` | pop the window out (floating) |
| `Ctrl+W` | close the window — and **quit the app** if it is the last one |
| `Cmd+M` | minimise to the Dock — macOS's own key; `Alt+M` is unbound on purpose |
| `Alt+Shift+M` | bring the focused app's windows back |
| `Alt+-` / `Alt+=` | resize (150px per press) |
| `Alt+Shift+;` | enter service mode (table below) |

`Alt+A` is between **windows** — it is what you want when two apps share the
same workspace. For switching **workspace**, the keys are `Alt+1..9`; `Alt+Tab`
belongs to AltTab and does not touch workspaces.

`Alt` + `` ` `` walks **every** window in the workspace in tree order and wraps
at the end, while `Alt+A` only alternates between the **last two**. The
`--boundaries workspace` in the binding is what holds the cycle inside the
workspace: without it, `dfs-next` crosses into the neighbouring monitor's
workspace.

`Alt+H/L` **crosses monitors** as of 2026-09-10, and did not before: AeroSpace's
`focus` assumes `--boundaries workspace` when you say nothing, and with that the
focus never left the current screen — in a workspace with two windows it just
bounced between them, which is exactly what "the shortcut is stuck on this
monitor" looks like. `--boundaries all-monitors-outer-frame` in the bindings is
what frees it, and `move` got the same for symmetry.

**`Alt+J/K` did not get that, and on the same day it got it and it was undone.**
The columns of this desk sit side by side, so horizontal is the axis that means
"next screen"; vertical only ever means "the other window in this workspace".
With the lid **open** the difference shows: the MacBook sits physically
**below** the externals, and then `Alt+J` stopped meaning "the window below" and
started meaning "fall onto the laptop panel". Worse on `Alt+Shift+J`, which
threw the window down there — and a window that changes monitor changes
**workspace** with it, silently, so the next `Alt+1/2/3` showed it somewhere you
did not choose. On the Mancer in portrait, with Teams on top and Slack below,
that is exactly the key you use to get from one to the other.

Nothing is lost: deliberate travel between panels is `Alt+Ctrl+H/J/K/L`, which
acts on the **monitor** and wraps around. It is also what you want when there is
**no** window in the requested direction — the neighbouring screen is empty, or
you just want to hop panels.

**Service mode** — `Alt+Shift+;` and then **one** key; every option returns to
main mode by itself:

| Key | Action |
|---|---|
| `Esc` | reload the config and leave |
| `R` | reset the layout you scrambled |
| `F` | toggle floating/tiling |
| `Backspace` | close every window but this one |
| `Alt+Shift+H/J/K/L` | join this window into the neighbour's container |

The monitors behave as **a single screen**: one key switches every screen at
once. Idea ported from `windows/glazewm/config.yaml`.

There are **three layouts**, one per screen count, because no single shape
serves all three: the three-screen file hides a third of the workspaces behind
the others when there are only two, and the two-screen one leaves half of them
**with no key at all** when there is only one (that story is in the one-screen
section below). `macos/aerospace/apply-layout.py` merges `aerospace.base.toml`
with a fragment and reloads:

```sh
./macos/aerospace/apply-layout.py          # detect the screens and apply
./macos/aerospace/apply-layout.py 3mon     # force a layout
./macos/aerospace/apply-layout.py --dry-run
```

> ⚠️ **Opening or closing the lid changes the screen count** — and therefore the
> right layout. At the desk in clamshell there are two (`2mon`); raising the lid
> makes three (`3mon`); unplugging everything and leaving the house makes one
> (`1mon`).
>
> This is automatic since 2026-09-08, via the `displaywatch` LaunchAgent
> (`./macos/bootstrap.sh displaywatch`). Nothing in the system offered that
> trigger: launchd fires on files, not on screens, and AeroSpace 0.21.3 only has
> `on-focus-changed`, `on-focused-monitor-changed` and `on-window-detected` —
> none of which fires when a panel appears or disappears. `display-watch.swift`
> fills the hole by listening to CoreGraphics and calling `apply-layout.py`.
>
> Two deliberate delays inside it: **3s** after the last event, because a single
> plug generates a burst of callbacks *and* because `apply-layout.py` asks
> AeroSpace for the count, which takes a moment to agree with CoreGraphics —
> firing immediately reads the **old** count. And **10s** at startup, which is
> the race with AeroSpace's server coming up at login.
>
> A resolution change fires **nothing** (`setModeFlag` is outside the filter on
> purpose): it does not change the screen count, so it cannot change the layout.
>
> ```sh
> tail -f ~/Library/Logs/aerospace-display-watch.log
> launchctl print gui/$UID/dev.luannunes.aerospace-display-watch
> ```

**Two-screen layout** (`layout-2mon.toml`) — six workspaces, desktops in pairs.
**This is the everyday layout**, because both of this machine's setups are
pairs: at the desk, Alienware + Mancer with the MacBook **closed**; on the road,
MacBook + ARZOPA. The columns are by role, so the same file serves both:

| | Column A (secondary) | Column B (primary) |
|---|---|---|
| **`Alt+1`** work | ws 1 ← Ghostty, Toggl, Hoppscotch | **ws 2** ← IntelliJ, VS Code |
| **`Alt+2`** chat | ws 3 ← Teams on top, Slack below | **ws 4** ← Claude, Codex, WhatsApp, Spotify |
| **`Alt+3`** browsers | ws 5 ← Notion | **ws 6** ← Chrome, Safari |

At the desk, column A is the **Mancer in portrait** and B is the **Alienware**;
on the road, A is the **MacBook**'s screen and B is the **ARZOPA**. Not one line
of the file changes between the two — what decides is which monitor has the menu
bar.

`Alt+4/5/6` move one screen only. `Alt+7/8/9` stay **unbound** — six workspaces
need six keys, and every unused `Alt+<key>` is a key given back to zsh and
Neovim.

**Teams and Slack own column A of the chat desktop outright**, one above the
other — ws 3 in the two-screen layout, ws 4 in the three-screen one. At the desk
that column is the Mancer in portrait (1440x2560), where
`default-root-container-orientation = 'auto'` resolves to a **vertical** split,
so two windows there are already a top half and a bottom half. Chat is the one
thing that reads better tall than wide, and that is what the panel is for.
Claude, Codex, WhatsApp and Spotify went to the wide screen together.

What guarantees **Teams on top** rather than "whichever you opened first" is the
second command in the rule: `on-window-detected` has no way to say "insert at
position 0", so the window is placed and then nudged — Teams one step up, Slack
one step down.

```toml
{ if.app-id = 'com.microsoft.teams2', run = ['move-node-to-workspace 3 --focus-follows-window', 'move --boundaries workspace --boundaries-action stop up'] },
```

> ⚠️ **Every rule has to fit on one line.** `apply-layout.py`'s re-homing reads
> the `APP_RULES` block with a line-oriented regex; a rule broken across two
> lines is a rule it silently skips, and then the app keeps the workspace the
> old layout gave it. `--boundaries-action stop` is not decoration either: the
> default for `move` is `create-implicit-container`, which instead of doing
> nothing would wrap the window in a nested container when it is already at the
> end.

> On the road that same column is the MacBook's screen, which is **landscape** —
> `auto` splits horizontally and the two land side by side, with the nudges
> doing nothing. Fine: the pairing is what matters, the orientation is the
> monitor's business.

**Three-screen layout** (`layout-3mon.toml`) — nine workspaces, desktops in
trios, with a third column: `Alt+1` = ws 1/2/3, `Alt+2` = 4/5/6, `Alt+3` =
7/8/9, and `Alt+4..9` as the escape hatch.

In those two, the columns are by **role**: column A is `secondary` (the screen
that is not the primary one) and B is `main`. Changing which monitor is the
primary flips the columns by itself.

**One-screen layout** (`layout-1mon.toml`) — the same six workspaces as the
two-screen layout, **one key each**: `Alt+1..6` go literally to the workspace of
the same number. It is the only layout where `Alt+<n>` means exactly that.

| | key | |
|---|---|---|
| ws 1 | `Alt+1` | Ghostty, Hoppscotch, Toggl |
| ws 2 | `Alt+2` | IntelliJ, VS Code, Android Studio |
| ws 3 | `Alt+3` | Teams on top, Slack below |
| ws 4 | `Alt+4` | Claude, Codex, WhatsApp, Spotify |
| ws 5 | `Alt+5` | Notion |
| ws 6 | `Alt+6` | Chrome, Safari, Firefox |

> ⚠️ **This file was born from a bug, on 2026-09-11.** Until then a single
> screen was served by `layout-2mon.toml`, on the theory that a pair layout
> "degrades" to six workspaces on one screen. It does not degrade — it
> **breaks**. The keys there are pairs:
>
> ```toml
> alt-1 = ['workspace 1', 'workspace 2']
> ```
>
> and both commands land on the **same** monitor when only one exists, so the
> second overwrites the first and you always arrive at the **even** workspace.
> `Alt+1/2/3` reached ws 2, 4 and 6; **ws 1, 3 and 5 had no key at all**, and
> `Alt+4/5/6` was no rescue because it binds the even half too. Not a corner
> case: ws 1 is the terminal and ws 3 is Teams + Slack, so the two workspaces
> reached for most often were the two that could not be reached. Found at a
> café, with Ghostty sitting on ws 1 and no key able to get to it.

**Why six workspaces and not three.** One screen shows one workspace, so the
pairing has nothing left to say and folding each desktop down to a single
workspace looks like the obvious move. It is the wrong one: it would put the
terminal and the IDE back together, which the two-screen layout separates
precisely because sharing a workspace leaves the IDE a third of a screen. Six
workspaces with one app slot each keep **every app on the same number across all
three layouts** — and that is what makes closing the lid free: `apply-layout.py`
re-homes open windows when the layout changes, and with identical numbers on
both sides it finds nothing to move.

**The app rules are not copied, they are inherited.** `layout-1mon.toml`
declares

```toml
# ---8<--- APP_RULES = layout-2mon.toml
```

and `apply-layout.py` fetches that section from the other file. Which app lives
on which workspace is a decision about **apps**; how many workspaces are visible
at once is a decision about **screens**. Only the second changes when the lid
closes, so installing a new app is still editing **one** file —
`layout-2mon.toml` — and nothing else. Inheritance is **one level only** and the
body of an inheriting section must be comments: both are checked, and both fail
loudly instead of silently.

**The terminal and the IDE are on different columns on purpose.** Sharing a
workspace left the IDE with a third of the screen, and the reflex was to press
`Alt+F` to compensate — which never holds, because AeroSpace's `fullscreen`
means "the focused window fills the workspace", not a maximised state. There is
no setting to make it persistent: I checked every configuration key in the
0.21.3 binary. One window per workspace is the answer the `[gaps]` block already
assumed.

> **Resolution on the three screens — the sum is always dots per inch.** None of
> them runs at the default macOS picks on its own, and the reason is the same
> for all three: the MacBook screen's density (~125 ppi) is the reference, and
> macOS's default errs in both directions depending on the panel size.
>
> | Screen | Mode | effective ppi | Why |
> |---|---|---|---|
> | **Alienware AW3225QF** 32" 4K | 3008×1692 HiDPI @240Hz | ~109 | the default was 1920×1080 (~70 ppi) — UI at nearly twice the MacBook's size |
> | **Mancer TE-3217G** 24" 2K | 1440×2560 portrait, 1:1 | ~123 | native already matches the MacBook; HiDPI here would halve the usable area |
> | **ARZOPA** 16" portable | 1920×1200 HiDPI | ~141 | macOS only exposed up to 1280×800 (~94 ppi), less area than the MacBook despite the bigger screen |
>
> ```sh
> betterdisplaycli set --namelike=AW3225QF --resolution=3008x1692 --hiDPI=on
> betterdisplaycli set --namelike=ARZOPA   --resolution=1920x1200 --hiDPI=on
> ```
>
> **On the Alienware, HiDPI is not optional.** It is a QD-OLED panel, whose
> subpixel is triangular rather than striped — text rendered at 1:1 comes out
> with colour fringing on the edges. The scaled mode renders at double and
> downsamples, and that is what keeps the text clean. The 240Hz survives the
> scaling.
>
> I asked for 3200×1800 and macOS settled on **3008×1692**: 3200 is not in the
> list this panel exposes. It is the neighbour, and the density difference is
> ~7 ppi.
>
> **The ARZOPA was a deliberate choice against my initial recommendation** of
> matching density (1600×1000, ~118 ppi): dense corporate UI — Domo, VID Central
> and the like — needs width, and cutting content costs more than small text. If
> it ever strains the eyes, `--resolution=1600x1000` undoes it.
>
> **The Mancer caps at 72Hz** at that resolution — it is the ceiling the panel
> offers over the current connection, not a setting. For a terminal and chat
> screen it does not bother; if it ever does, the suspect is the cable/hub
> before the monitor.
>
> None of this lives in the repo: they are BetterDisplay preferences, and
> `defaults.sh` does not reproduce them. On a new machine `brew bundle` installs
> the app and the modes are redone by hand. Worth turning on *Protect
> resolution* in the app's menu so macOS does not revert on reconnect.
>
> **Do not trust that key's `get`.** CLI 4.3.6 returns a broken interpolation
> string (`true ? ON : OFF)`) and the value is **constant**: sending
> `--protectResolution=off` and reading it back still gives `true`. Worse,
> `=false` is rejected with `Failed.` while `=off` and `=0` pass silently, so
> you can turn the protection off believing you did not. What actually answers
> is the plist:
>
> ```sh
> defaults read pro.betterdisplay.BetterDisplay | grep protectResolution
> ```
> ```
> "protectResolution@Display:3" = "1920x1200 HiDPI";   # ARZOPA
> "protectResolution@Display:4" = "3008x1692 HiDPI";   # Alienware
> "protectResolution@Display:5" = "1440x2560 LoDPI";   # Mancer
> ```
>
> There is no on/off boolean: **the presence of the string is the on state**,
> and it holds the pinned mode. The `@Display:N` is BetterDisplay's `tagID`,
> **not** the `displayID` — the two cross over between panels. To tell which is
> which, `betterdisplaycli get --identifiers`, or find the built-in by
> `builtIn@Display:N = 1`.
>
> The same goes for the **refresh rate**: `--protectRefreshRate=on` pins the
> current value and writes `protectRefreshRate@Display:4 = 240Hz`. Worth turning
> on alongside the resolution — it is the same kind of revert on reconnect.

> **Brightness: the Alienware accepts DDC, the Mancer does not.** In clamshell
> the brightness keys no longer have the MacBook's screen to control, and what
> solves it is BetterDisplay speaking DDC to the monitor. Tested on both, on
> 2026-09-08:
>
> ```sh
> betterdisplaycli get --namelike=AW3225QF --ddc --vcp=luminance   # -> 100
> betterdisplaycli get --namelike=TE-3217G --ddc --vcp=luminance   # -> Failed.
> ```
>
> On the Alienware writing works too (`set --hardwareBrightness=70%` and the DDC
> read comes back `70`), and after that the plist gains a controller that did
> not exist before: `value@hardwareBrightness-DDCController@Display:4`. It is
> real **backlight** brightness, not software dimming's dark overlay. The Mancer
> is left with only `softwareBrightness`, which washes the image out instead of
> darkening it.
>
> ⚠️ **`--hardwareBrightness=100%` does not return exactly 100.** It came back
> `94` on the DDC read — BetterDisplay's scale does not map 1:1 onto the VCP.
> For an exact value, write the VCP directly:
>
> ```sh
> betterdisplaycli set --namelike=AW3225QF --ddc --vcp=luminance --value=100
> ```
>
> **Making the F1/F2 keys control the Alienware is a UI step.** There is no CLI
> feature for it (checked across the whole of `betterdisplaycli help`, 313
> lines) and no key exists in the plist until it is turned on the first time —
> it is the app's **Settings → Keyboard** panel. The DDC is already in place
> underneath; all that is left is telling the app to intercept the keys.

> **Changing the primary monitor has a CLI too**, and it is faster than
> Arrange…: `betterdisplaycli set --namelike=AW3225QF --main=on`. There is no
> undo — only designating another screen as primary.

> **With two screens, column C swallows windows.** It collapses onto the same
> screen as column B, so ws 3/6/9 fight the primary monitor with ws 2/5/8 — and
> `Alt+1..3` ends up showing column B. A window that lands in column C simply
> vanishes from view, and it looks like the monitors stopped switching together.
>
> Only an app **with no rule** gets there, since it is born wherever the focus
> is. If an app disappears like that, the fix is not to touch the columns — it
> is to give it a rule in `on-window-detected`. That was the case for
> Hoppscotch, now pinned to ws 1, and for Notion, pinned to ws 5 on 2026-09-10.

> **`on-window-detected` fires on a window that is BORN, and un-minimising is
> not being born.** Discovered while testing Notion's new rule: it was running
> with its only window minimised — invisible to `aerospace list-windows`,
> because a minimised window leaves the tree — and `open -a Notion` **restored**
> that window instead of creating one. It came back on whichever workspace the
> focus was on, not ws 5, and the rule looked broken. After a real `quit` and a
> relaunch, it went to ws 5 on the first try.
>
> It applies to `Alt+Shift+M` too, which is exactly that restoration: it brings
> the window back, but does not re-route it. If it comes back in the wrong
> place, `Alt+Shift+<n>` pushes it — the rule did not fail.

> **Which screen is the primary decides where the work happens**, because column
> B is `main` and A is `secondary`. Changing the primary monitor flips the two
> columns automatically, with nothing to edit — that is how the ARZOPA went from
> side panel to work screen, and it is what lets the same `layout-2mon.toml`
> serve both the desk and the road.
>
> You change the primary in System Settings → Displays → **Arrange…**, dragging
> the white bar. It is not a `defaults write`, so `defaults.sh` does not
> reproduce it.
>
> **With two screens no monitor is named**, and that is deliberate: `^arzopa$`
> in column A would collide with column B the moment the ARZOPA became the
> primary, and the workspaces would pile onto a single screen. It has happened
> twice.
>
> **With three screens a name is unavoidable.** `main` and `secondary` partition
> two screens exactly, but on the third, `secondary` matches *two* and cannot
> tell column A from column C. The rule that keeps it safe: **only ever name a
> screen that is never the primary one**. That is why `layout-3mon.toml` names
> the Mancer (column A) and `built-in` (column C), and leaves the Alienware
> unnamed — which makes it the designated primary. Moving the menu bar to
> another screen means moving the names with it.
>
> Seen live on 2026-09-08, at both ends. With the lid open and the MacBook still
> primary, ws 2/5/8 **and** 3/6/9 all landed on the built-in and the Alienware
> got no workspace at all — exactly the collision described above. With the lid
> closed and `apply-layout.py` run, the pair came out clean:
>
> ```
> 1,3,5 -> TE-3217G     (column A, portrait)
> 2,4,6 -> AW3225QF     (column B, primary)
> ```
>
> `layout-2mon.toml` did not need **one line** edited for the new hardware. That
> is the return on having written the columns by role.

Opening an app **takes you with it** to its workspace
(`--focus-follows-window` on every rule). Without that, clicking the Dock moved
the window to a possibly invisible workspace and you sat staring at the old
screen thinking the app had not opened.

Two consequences of that, both expected:

Opening an app **breaks the trio** — only that workspace's screen changes, the
other two stay where they were. An `Alt+1..3` afterwards re-syncs all three.

At **login**, with several apps restoring at once, each one matching a rule
pulls the focus when its window appears. The first few seconds jump between
screens before settling on the last one to come up.

The rule only fires when the window is **born** — an app that is already open
does not move itself after a `reload-config`. Use `Alt+Shift+<n>` once, or close
and reopen it.

> **Switching layouts is the exception, as of 2026-09-08.** `apply-layout.py`
> re-homes already-open windows when — and **only when** — the layout actually
> changes. Without that, opening or closing the lid left each app on the
> workspace the *previous* layout had given it: Safari opened with the lid up
> went to ws 8 by the `3mon` rule, and closing the lid left it there — on a
> workspace `2mon` does not even map a key for, so **invisible and unreachable
> from the keyboard**. It looked like a window that "would not expand".
>
> The trigger is the layout changing, not the script running: running
> `apply-layout.py` again without switching layouts touches nothing, so it does
> not undo what you positioned by hand. It prints what it moved:
>
> ```
> apply-layout: com.apple.Safari 6 -> 8
> ```
>
> `--no-rehome` turns the behaviour off for one run. And the re-homing
> deliberately does not use `--focus-follows-window`: the rules use it so that
> opening an app takes you with it, but here a dozen windows may move at once,
> and following each one would leave the focus somewhere random.

> **Closing moved off `Alt+W` on 2026-09-10.** Option is this keyboard's accent
> key, so writing Portuguese means living on top of the modifier that closes
> windows — and since closing takes the app with it (block below), one slip in
> "ação" brought the whole session down. Matching GlazeWM's `win+w` is not worth
> that.
>
> **`Ctrl+W` costs more than the `Alt+W` it replaces**, and it is good to know
> before it surprises you: AeroSpace grabs `Ctrl+W` globally the same way it
> grabs `Alt`, so zsh loses `backward-kill-word` (the `Ctrl+W` every shell has)
> and Neovim loses `Ctrl+W`, the prefix for window commands. If that half hurts
> more than the other, `Ctrl+Shift+W` belongs to nobody and the swap is one line
> in `aerospace.base.toml`.
>
> Nothing else here is on `Alt`: unbinding `Alt+M` on 2026-09-11 handed zsh back
> `copy-prev-shell-word`, and `Alt+.` (insert last argument), the one actually
> used day to day, was never touched.

> **Minimising takes the window out of the tree.** It goes to live in the Dock,
> AeroSpace stops seeing it, and `Alt` + `` ` `` does not find it, because that
> only walks what is still in the tree. `Alt+Shift+M` is the way back (block
> below). If the intention was just to get the window out of the way,
> `Alt+Shift+F` (pop it out as floating) is usually what you wanted.
>
> Which is why **`Alt+M` no longer minimises**. It did until 2026-09-11, and it
> was the only key in this config that produced a state neither switcher can
> see. The failure never looks like a minimised window either — it looks like
> "`Cmd+Tab` stopped opening Chrome", because the browser had one window and it
> was in the Dock. Minimising is now macOS's `Cmd+M` and nothing else: still
> available, still the same state, but pressed on purpose rather than by a slip
> on a tiling key.

> ⚠️ **"I pressed `Cmd+Tab`, picked the app and nothing happened."** It is not
> AeroSpace eating the key: macOS's `Cmd+Tab` activates an **app**, never a
> window. If the app has no window to show, it becomes frontmost and the screen
> does not change. The Dock icon works because a click on it sends a *reopen*
> event, which is a different thing — it asks the app to restore or create a
> window.
>
> Two states lead there, and an app can be in both:
>
> - **minimised windows** — `Cmd+Tab` only restores them if you hold `⌥` before
>   releasing `⌘`. That trick is native and works with nothing installed.
> - **no windows** — a `Cmd+W` on the last one leaves the app alive and empty.
>   That is how Finder and Claude were caught during the diagnosis. `Ctrl+W`
>   does not produce that state: `--quit-if-last-window` takes the app with it.
>
> `Alt+Shift+M` solves both with a single call: `open -b <bundle-id>`, the same
> *reopen* event as the Dock click. AppKit's default handling of it is exactly
> what is wanted — with no visible window it un-minimises the last one, or
> creates one if there is none. Tested on Spotify, Slack and Teams.
>
> It is a script (`macos/aerospace/raise-frontmost.sh`) only because AeroSpace
> has no command to fire that. **It deliberately does not touch Accessibility:**
> the first version cleared `AXMinimized` window by window through System
> Events, worked, and left the key only as reliable as a permission we watched
> drop out on its own mid-session (`osascript is not allowed assistive access`,
> -25211). `lsappinfo` and `open` go through LaunchServices, which asks for
> nothing.
>
> Where the window reappears depends on the case: when `open -b` **creates** a
> window, the `on-window-detected` rule fires and it goes to its usual
> workspace; when it only un-minimises, nothing is created, the rule stays
> silent, and it has been seen coming back both on the rule's workspace and on
> the visible one. `Alt+Shift+<n>` moves
> it if it lands in the wrong place.

> **AltTab, on the other hand, DOES list a minimised window** — with a small
> status icon marking it — and picking it brings the window back. This file said
> the opposite until 2026-09-11, and that wrong sentence cost a diagnosis: it is
> a preference, `showMinimizedWindows`, whose default is *Show*
> (`ShowHowPreference.show`, index `0`, read off the AltTab source rather than
> guessed). Check it in AltTab → Settings → Windows, or:
>
> ```sh
> defaults read com.lwouis.alt-tab-macos showMinimizedWindows   # absent = default = Show
> ```
>
> So after a `Cmd+M`, the switcher that answers is `Alt+Tab`, not `Cmd+Tab`.
> `Cmd+Tab` is macOS's own and is per-APP — no setting in AltTab changes what it
> does, because AltTab is not involved. `Alt+Shift+M` remains the one-press
> answer when the app has no window at all.
>
> One more thing about these keys: every `*ToShow`/`showHow` preference exists
> **once per AltTab shortcut**. Shortcut 1 uses the bare names above, shortcut 2
> uses `showMinimizedWindows2`, `screensToShow2`, and so on
> (`Preferences.indexToName`). Setting the bare key changes `Alt+Tab` only.

> **`Ctrl+W` quits the app along with the last window**
> (`--quit-if-last-window`), as on Windows and in Omarchy — and contrary to the
> macOS convention, where the app stays alive with an empty menu bar. It was a
> deliberate choice: an app you cannot see but that keeps running is exactly the
> state a tiling WM exists to avoid.
>
> The cost shows up in apps whose window **is** the session: Ghostty's last
> window takes the shells with it, and the browser's last window quits the
> browser. When you want to close only the window and keep the app, `Cmd+W` is
> still there.

> ⚠️ **AeroSpace grabs `Alt+<key>` globally**, before the focused app. That is
> why `Alt+C` is **not** mapped — it belongs to fzf. Check the file before
> adding a new binding.
>
> The same goes for `Ctrl+W`, the only binding here outside `Alt`. Let it stay
> the only one: `Ctrl` is where the terminal keeps everything, and `Alt` at
> least had keys to spare.

> **Primary monitor.** macOS's "main" display is the one with the menu bar, and
> by definition it is the one at origin `(0,0)`. At the desk it is the
> **AW3225QF**, not the MacBook's screen; on the road it is the **ARZOPA**. You
> change it in System Settings → Displays → **Arrange…**, dragging the white bar
> to the desired monitor — the other screens' relative positions are preserved.
> It is not a `defaults write`, so `defaults.sh` does not reproduce it: it is a
> manual step on a new machine.
>
> macOS stores the arrangement **per screen configuration**, and clamshell is a
> different configuration from lid-open — dragging the white bar with the lid
> open decides nothing about the closed mode.
>
> In practice, closing the lid **already put the menu bar on the Alienware by
> itself** (verified 2026-09-08): without the built-in, macOS promotes one of
> the externals and picked the higher-resolution one. It needed no Arrange… at
> all. Only go back there if it promotes the wrong one.

> ⚠️ **"Displays have separate Spaces"** must be off — with it on, macOS
> repositions windows on its own and fights any tiler. `defaults.sh` already
> writes it (`com.apple.spaces spans-displays`), but it only takes effect after
> a **logout**; the key is read at login.

---

## 7. Terminal — what changes coming from WSL

The biggest mental shift: **the Windows ↔ Linux border is gone**. There is no
more `/mnt/c`, no `\\wsl$`, no X410, no `clip.exe`. One Unix system, and Finder
sees the same files.

| WSL | macOS |
|---|---|
| `explorer.exe .` | `open .` |
| `clip.exe` / `Get-Clipboard` | `pbcopy` / `pbpaste` |
| `wslpath` | — unnecessary |
| X410 + `DISPLAY` | — apps are native |
| `nala` / `apt` | `brew` |
| `systemctl` | `launchctl` / `brew services` |
| `~/.config` | `~/.config` **and** `~/Library/Application Support` |
| `/etc/hosts` | `/etc/hosts` (same) |

```sh
cat id_rsa.pub | pbcopy     # copy to the system clipboard
pbpaste > file.txt
open -a "Google Chrome" .   # open something with a specific app
say "build finished"        # audible notice at the end of a long build
```

**Neovim:** `clipboard=unnamedplus` starts working directly via `pbcopy`. The
whole `clip.exe` hack in `init.lua` turns itself off (`vim.fn.has("wsl")`).

**Ghostty:** `Cmd+D` split to the right, `Cmd+Shift+D` below,
`Cmd+Option+arrows` to navigate, `Cmd+Shift+Enter` zoom, `` Cmd+` `` drop-down
terminal, `Cmd+Shift+,` reloads the config.

> ⚠️ **APFS is case-insensitive by default.** `File.ts` and `file.ts` are the
> same file. A repo that has both (it happens in a large project coming from
> Linux) will produce strange conflicts in `git status`. If you hit that, create
> a case-sensitive APFS volume just for that project.

---

## 8. Packages — brew

A single manager, in place of `nala` + `scoop`:

```sh
brew install ripgrep            # CLI (formula)
brew install --cask raycast     # .app app (cask)
brew search <term>
brew info <package>
brew uninstall <package>
brew update && brew upgrade     # updates everything, CLI and apps
brew services start postgresql  # daemons (the systemctl of this world)
brew doctor                     # diagnostics
brew autoremove && brew cleanup # clear orphans and caches
```

Everything this machine has is in `macos/Brewfile`. Installed something new by
hand? `brew bundle dump --file=macos/Brewfile --force` and commit it.

---

## 9. Dev on Apple Silicon

| Point | What to know |
|---|---|
| brew prefix | `/opt/homebrew`, **not** `/usr/local` (that one is Intel) |
| amd64 Docker images | work via Rosetta on OrbStack; force it with `--platform linux/amd64` |
| **End of Rosetta** | it goes away in macOS 28 (Oct 2027). The exception kept is an Intel binary **inside a Linux VM** — that is, your amd64 containers survive; native Intel apps do not. Always prefer an Apple Silicon build |
| `docker` / `docker compose` | identical — OrbStack provides the same CLI |
| asdf: node, java, go, kotlin, dotnet | have native arm64 builds, install normally |
| **asdf: python 3.6.2 / 2.7.13** | **do not compile here** — they predate Apple Silicon. Pin a current 3.x |
| JetBrains | via Toolbox, the "Apple Silicon" build (not the Intel one) |
| Java | temurin arm64; if a project requires x86, `asdf` has Intel builds via Rosetta |
| Performance | 48 GB leaves comfortable room for IDE + OrbStack + amd64 emulation at once |

---

## 10. "Why does it not work" — permissions

macOS blocks by default, and frequently **with no error message**. The three
places in System Settings → Privacy & Security:

| Permission | Who needs it | Symptom without it |
|---|---|---|
| **Accessibility** | AeroSpace, Raycast, AltTab, Karabiner | the app opens and simply does nothing |
| **Screen & System Audio Recording** | AltTab | lists the windows, but with no title or thumbnail |
| **Full Disk Access** | Terminal/Ghostty, backup | "Operation not permitted" in `~/Library`, Mail, etc. |
| **Input Monitoring** | Karabiner | keys are not captured |

**Gatekeeper**: an app downloaded outside the App Store gives "cannot be
opened".

> ⚠️ The **right-click → Open** trick was **removed in macOS Sequoia** and is
> still removed in Tahoe 26. Every tutorial that teaches it is out of date.

The current path: **System Settings → Privacy & Security** → scroll to
**Security** → **Open Anyway**. That button only appears for **~1 hour** after
the blocked attempt; if it is gone, try opening the app again and go back there.

Via CLI: `xattr -d com.apple.quarantine /Applications/App.app`. Apps installed
with `brew install --cask` come without quarantine already.

---

## 11. Backup and security

| Item | Action |
|---|---|
| **FileVault** | turn it on day 1 (Privacy & Security). An unencrypted disk in a work laptop is a risk |
| **Time Machine** | an external SSD. It is the most painless backup there is — it restores the whole machine |
| **Touch ID for `sudo`** | already done by `defaults.sh` via `/etc/pam.d/sudo_local` |
| **Find My Mac** | turn it on along with the Apple Account |
| **Firmware password** | optional; Apple Silicon already protects well with FileVault + Secure Enclave |

`sudo_local` survives a system update, unlike editing `/etc/pam.d/sudo`.

---

## 12. Equivalents for your Windows stack

| Windows | macOS |
|---|---|
| Windows Terminal | **Ghostty** |
| PowerShell | zsh (the same one as WSL) |
| Flow Launcher | **Raycast** |
| Ditto | **Maccy** |
| Windhawk / TranslucentTB | native — `background-blur = macos-glass-regular` in Ghostty |
| FancyZones / Win+arrows | **AeroSpace** |
| Alt+Tab | **AltTab** — per-window switcher on `Alt+Tab`; `Alt` + `` ` `` cycles this workspace's windows in AeroSpace, and `Cmd+Tab` stays macOS's per-app switcher |
| Scoop | `brew --cask` |
| Nala / apt | `brew` |
| Docker Desktop | **OrbStack** |
| Windows registry | `defaults write` (see `macos/defaults.sh`) |
| Task Manager | Activity Monitor + **Stats** in the menu bar |
| Bibata cursor | ❌ macOS has no cursor theme — only size/contrast under Accessibility |

---

## 13. The 4-week plan

**Week 1 — do not break anything.** Run `bootstrap.sh` and `defaults.sh`, log
out, grant the Accessibility permissions, validate `ssh -T git@github.com` and
`git clone` on both remotes. Use `Cmd+Space` (Raycast) for everything. That is
all.

**Week 2 — hands.** Memorise the table in section 2, especially `Cmd+←/→`,
`Fn+Delete` and `Cmd+Q` vs `Cmd+W`. Enable Caps Lock → Esc. Learn the 4 trackpad
gestures.

**Week 3 — windows.** Only then turn AeroSpace on for real. Start with
`Alt+1..4` and `Alt+H/J/K/L`. The rest of the bindings come later.

**Week 4 — heavy work.** Bring up the Domo environment: OrbStack, `kubectl`,
`tug`, `domo-admin`. This is where you find out what is still missing — and then
you adjust the `Brewfile` and commit.

---

## Quick reference

```sh
./macos/bootstrap.sh        # machine setup (re-runnable)
./macos/defaults.sh         # system preferences
brew bundle --file=macos/Brewfile
aerospace reload-config
ghostty +list-themes
defaults read com.apple.dock                 # see an app's current config
defaults delete com.apple.dock <key>         # revert one tweak
```
