-- Tracked in the dotfiles repo as omarchy/hypr/monitors.lua and symlinked to
-- ~/.config/hypr/monitors.lua. Omarchy's own defaults live in
-- /usr/share/omarchy/default/hypr/ and are loaded BEFORE this file, so keep
-- only personal overrides here — that is what lets `omarchy update` improve
-- the defaults without ever rewriting this file.

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
