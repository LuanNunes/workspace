# Windows Desktop Customization

Lightweight visual-tweaking stack for Windows 11, installed and managed via
[Scoop](https://scoop.sh/).

## Stack overview

| Tool | Purpose | Install |
|------|---------|---------|
| **Windhawk** | Mod platform — taskbar styling, window tweaks, Explorer mods | `scoop install extras/windhawk` |
| **TranslucentTB** | Taskbar transparency / blur / acrylic effects | `scoop install extras/translucenttb` |
| **Flow Launcher** | Keystroke launcher (Alfred for Windows) | `scoop install extras/flow-launcher` |
| **Bibata Modern Ice** | Cursor theme | [GitHub release](https://github.com/ful1e5/Bibata_Cursor/releases) (not in Scoop) |

> **RoundedTB** was considered but its repo was archived in Sep 2023 and it
> breaks on recent Win 11 builds. Windhawk's *Taskbar Styler* mod covers the
> same functionality.

## Install everything

```sh
scoop bucket add extras            # one-time
scoop install extras/windhawk extras/translucenttb extras/flow-launcher
```

### Bibata Modern Ice (manual)

```sh
# download
curl -sL "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice-Windows.zip" \
     -o "$env:TEMP\Bibata-Modern-Ice-Windows.zip"

# extract
Expand-Archive "$env:TEMP\Bibata-Modern-Ice-Windows.zip" "$env:TEMP\bibata" -Force

# install (Regular size — also available: Large, Extra-Large)
rundll32 setupapi,InstallHinfSection DefaultInstall 132 \
    "$env:TEMP\bibata\Bibata-Modern-Ice-Regular-Windows\install.inf"
```

Then activate: **Settings → Bluetooth & devices → Mouse → Additional mouse
settings → Pointers → Scheme → Bibata-Modern-Ice → Apply**.

---

## Configuration

### Windhawk

Open Windhawk → **Browse** → install mods → configure each under **Installed →
(mod) → Settings**.

#### Recommended mods

**Taskbar**

| Mod | What it does | Key settings |
|-----|-------------|--------------|
| Windows 11 Taskbar Styler | Rounded corners, margins, segments, community themes (macOS dock, XP, Vista…) | **Theme** dropdown for presets; **Control styles** for XAML pairs (`Target` + `Style`); **Resource variables** for color/opacity overrides |
| Taskbar height and icon size | Control taskbar height and icon dimensions | `Taskbar height` (default ~48 px), `Icon size` |
| Taskbar tray icon spacing | Spacing and grid layout for system-tray icons | `Horizontal spacing`, `Icon grid columns` |

**Windows & title bars**

| Mod | What it does | Key settings |
|-----|-------------|--------------|
| Custom Window Corner Radius | Set window corner roundness | `Corner radius` in px (Win 11 default: 8; try 12–16 for rounder, 0 for square) |
| Windows 11 Custom Title Bar Colours | Consistent title-bar colors, especially in dark mode | `Title bar color`, `Inactive title bar color`, `Use accent color` toggle |
| Center Titlebar | Center-align title-bar text | On/off — no extra settings |

**Explorer & UI**

| Mod | What it does | Key settings |
|-----|-------------|--------------|
| Windows 11 Start Menu Styler | Themes for the Start Menu (translucent, Aero, Win 10…) | **Theme** dropdown; **Control styles** for XAML tweaks |
| Windows 11 File Explorer Styler | XAML-based Explorer styling | Theme presets and manual overrides |

#### Taskbar Styler quick example

Floating taskbar with rounded corners (dark):

- **Target:** `Taskbar.TaskbarFrame`
- **Style:** `CornerRadius=15` `Margin=5,0,5,5` `Background=<acrylic color>#99000000</acrylic>`

#### Tips

- Click **Save** after every change — mods reapply in real time.
- Toggle a mod off under **Installed** if something looks wrong.
- After uninstalling or disabling a mod that affects Explorer/taskbar, **restart
  `explorer.exe`** for the change to take effect (Task Manager → explorer.exe →
  Restart task, or `taskkill /f /im explorer.exe && start explorer.exe`).
- Transparency colors use `#AARRGGBB` format (e.g. `#99000000` = black at 60 %
  opacity).

### TranslucentTB

Configure via the **system-tray icon** (right-click).

#### Effect options (per context)

| Option | Result |
|--------|--------|
| Normal | Default Windows style |
| Opaque | Solid color, no transparency |
| Clear | Fully transparent — only icons visible |
| Blur | Classic blur (Win 10 Aero style) |
| Acrylic | Modern blur with noise/tint (Fluent Design) |

#### Recommended setup (dark mode, uniform look)

1. **Desktop** → pick your effect (Acrylic works well in dark mode).
2. Set a **Color** — e.g. `#CC1a1a1a` (dark grey, 80 % opacity).
3. Set **Visible Window / Maximized Window / Start Menu / Search / Task View**
   all to **disabled** so the Desktop effect applies everywhere.
4. Enable **Open at boot**.

### Flow Launcher

1. Open via the Start Menu (first time) or your hotkey.
2. **Settings** (gear icon) → **General** → **Hotkey**: set your preferred
   shortcut (e.g. `Ctrl+Space` — `Alt+Space` is taken by the Windows system
   menu).
3. Browse **Plugin Store** for extras (calculator, clipboard history, bookmarks,
   shell commands, etc.).

---

## Uninstall

```sh
scoop uninstall windhawk translucenttb flow-launcher
```

Bibata cursor: **Settings → Mouse → Additional mouse settings → Pointers →
Scheme → Windows Default → Apply**, then delete the extracted folder.
