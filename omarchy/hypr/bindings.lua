-- Tracked in the dotfiles repo as omarchy/hypr/bindings.lua and symlinked to
-- ~/.config/hypr/bindings.lua. Omarchy's own defaults live in
-- /usr/share/omarchy/default/hypr/ and are loaded BEFORE this file, so keep
-- only personal overrides here — that is what lets `omarchy update` improve
-- the defaults without ever rewriting this file.

-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- ===========================================================================
--  hjkl window focus
-- ===========================================================================
-- Omarchy focuses with SUPER + arrows. This adds the vim spelling alongside
-- them: the arrows keep working, so this adds a way in without taking one away
-- — the same trade as the Ghostty split bindings on the Mac.
--
-- The modifier was not a choice here: SUPER + hjkl is the i3/sway/Hyprland
-- convention and the thing muscle memory expects. But three of the four keys
-- already had an owner, so each is unbound first and re-homed on a free key
-- rather than dropped. Only SUPER + H was free.
--
-- The re-homed commands are copied verbatim from Omarchy's own definitions:
--   default/hypr/bindings/tiling.lua      togglesplit, workspace-layout-toggle
--   default/hypr/bindings/utilities.lua   omarchy-menu-keybindings
-- Copies drift, so if one of these ever stops working, diff against those two
-- files first — Omarchy changing a command underneath is the likely cause.

hl.unbind("SUPER + J") -- was: Toggle window split      → SUPER + ALT + J
hl.unbind("SUPER + K") -- was: Keybindings              → SUPER + SHIFT + K
hl.unbind("SUPER + L") -- was: Toggle workspace layout  → SUPER + ALT + L

o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- The three displaced defaults, re-homed. Keybindings keeps the "K means
-- keybindings" mnemonic Omarchy already uses (SUPER+ALT+K is Tmux keybindings,
-- SUPER+CTRL+K is Herdr keybindings) — both of which were taken, and SHIFT+K
-- now belongs to the swap layer below, so the general menu takes the one
-- remaining K. A three-modifier chord is the right place for it: it is a
-- look-things-up menu, not a key pressed in the middle of doing something.
o.bind("SUPER + ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + SHIFT + ALT + K", "Keybindings", "omarchy-menu-keybindings")

-- ===========================================================================
--  hjkl window swap
-- ===========================================================================
-- The companion layer to the focus bindings above, mirroring Omarchy's
-- SUPER + SHIFT + arrows exactly as those mirror SUPER + arrows: same
-- modifier, same meaning, vim spelling. Commands from the same tiling.lua.
--
-- No unbinds here — all four keys were free, once Keybindings moved off
-- SHIFT+K just above.

o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
