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

-- The three displaced defaults, re-homed. SUPER + ALT + K was unavailable
-- (Tmux keybindings), which is why Keybindings lands on SHIFT instead of
-- keeping the group together on ALT.
o.bind("SUPER + ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + SHIFT + K", "Keybindings", "omarchy-menu-keybindings")
