#!/usr/bin/env python3
"""Apply a Windows Terminal theme to THIS machine, keyed by %COMPUTERNAME%.

Instead of copying settings.json wholesale (which would break defaultProfile and
drop machine-specific profiles like Ubuntu, Visual Studio, etc.), this script
MERGES:

  settings.base.json  (shared prefs: keybindings, cosmetic defaults)
  + themes.json       (the chosen theme: WSL/PowerShell colorScheme, font, opacity + every palette)
  + machines.json     (which theme this machine uses, by COMPUTERNAME)

into the settings.json that Windows Terminal actually uses, preserving the
machine's own profile list (GUIDs) and defaultProfile.

Usage:
  ./apply-theme.py                 # theme for the current machine (machines.json)
  ./apply-theme.py rose-pine       # force a specific theme
  ./apply-theme.py --dry-run       # show what would change, write nothing
  ./apply-theme.py --list          # list available themes
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def load_json(path):
    # tolerates the "//" comment keys and keeps insertion order
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def computername():
    """Windows %COMPUTERNAME%, as seen from inside WSL."""
    env = os.environ.get("COMPUTERNAME")
    if env:
        return env
    try:
        out = subprocess.run(
            ["cmd.exe", "/c", "echo %COMPUTERNAME%"],
            cwd="/mnt/c", stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            universal_newlines=True, timeout=10,
        ).stdout.strip()
        return out or "default"
    except Exception:
        return "default"


def win_settings_path():
    """WSL path to the Windows Terminal settings.json."""
    override = os.environ.get("WT_SETTINGS")
    if override:
        return Path(override)
    try:
        userprofile = subprocess.run(
            ["cmd.exe", "/c", "echo %USERPROFILE%"],
            cwd="/mnt/c", stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            universal_newlines=True, timeout=10,
        ).stdout.strip()
        wslpath = subprocess.run(
            ["wslpath", "-u", userprofile],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            universal_newlines=True, timeout=10,
        ).stdout.strip()
        base = Path(wslpath)
    except Exception:
        base = Path(f"/mnt/c/Users/{os.environ.get('USER', '')}")
    return base / ("AppData/Local/Packages/"
                   "Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json")


def is_powershell(profile):
    if profile.get("name") in ("PowerShell", "Windows PowerShell"):
        return True
    return "PowerShell" in profile.get("source", "")


def upsert_schemes(settings, schemes):
    existing = {s.get("name"): i for i, s in enumerate(settings.get("schemes", []))}
    settings.setdefault("schemes", [])
    for sch in schemes:
        name = sch.get("name")
        if name in existing:
            settings["schemes"][existing[name]] = sch
        else:
            settings["schemes"].append(sch)


def apply(settings, base, theme):
    # 1) shared top-level prefs (leave profiles/defaultProfile/schemes untouched)
    for key in ("copyFormatting", "copyOnSelect", "keybindings",
                "newTabMenu", "theme", "useAcrylicInTabRow"):
        if key in base:
            settings[key] = base[key]

    # 2) defaults = shared cosmetics + theme (WSL colorScheme, font, opacity)
    defaults = settings.setdefault("profiles", {}).setdefault("defaults", {})
    defaults.update(base.get("defaults", {}))
    defaults["colorScheme"] = theme["wslScheme"]
    defaults["opacity"] = theme["opacity"]
    defaults["font"] = {"face": theme["font"], "size": theme["fontSize"]}

    # 3) PowerShell profiles get the shell scheme/font; every other profile
    #    (WSL, cmd, …) inherits the WSL theme from `defaults`. Drop any
    #    per-profile colorScheme/font/opacity left over from a manual tweak —
    #    a profile-level override wins over `defaults`, so otherwise the
    #    machine's WSL scheme silently never shows (e.g. Ubuntu stuck on an old
    #    scheme while defaults already switched).
    shell_font = theme.get("shellFont", theme["font"])
    for prof in settings.get("profiles", {}).get("list", []):
        if is_powershell(prof):
            prof["colorScheme"] = theme["shellScheme"]
            prof["font"] = {"face": shell_font, "size": theme["fontSize"]}
        else:
            for key in ("colorScheme", "font", "opacity"):
                prof.pop(key, None)


def main():
    ap = argparse.ArgumentParser(description="Apply a Windows Terminal theme per machine.")
    ap.add_argument("theme", nargs="?", help="Force a theme (otherwise use machines.json).")
    ap.add_argument("--dry-run", action="store_true", help="Show the result without writing.")
    ap.add_argument("--list", action="store_true", help="List available themes.")
    args = ap.parse_args()

    themes_doc = load_json(HERE / "themes.json")
    themes = themes_doc["themes"]

    if args.list:
        for name, t in themes.items():
            print(f"  {name:<14} WSL={t['wslScheme']:<18} PowerShell={t['shellScheme']}")
        return

    base = load_json(HERE / "settings.base.json")
    machines = load_json(HERE / "machines.json")

    host = computername()
    theme_name = args.theme or machines.get(host) or machines.get("default")
    if theme_name not in themes:
        sys.exit(f"unknown theme: {theme_name!r} (see --list)")
    theme = themes[theme_name]

    settings_path = win_settings_path()
    if not settings_path.is_file():
        sys.exit(f"Windows Terminal settings.json not found: {settings_path}")

    settings = load_json(settings_path)

    upsert_schemes(settings, themes_doc["schemes"])
    apply(settings, base, theme)

    rendered = json.dumps(settings, indent=4, ensure_ascii=False)

    print(f"machine     : {host}")
    print(f"theme       : {theme_name}")
    print(f"WSL         : {theme['wslScheme']}  ·  font {theme['font']} {theme['fontSize']}  ·  opacity {theme['opacity']}")
    print(f"PowerShell  : {theme['shellScheme']}  ·  font {theme.get('shellFont', theme['font'])}")
    print(f"settings    : {settings_path}")

    if args.dry_run:
        print("\n--dry-run: nothing written.")
        return

    backup = settings_path.with_suffix(".json.bak")
    shutil.copy2(settings_path, backup)
    settings_path.write_text(rendered + "\n", encoding="utf-8")
    print(f"\n✓ applied. backup at {backup}")
    print("  Reopen Windows Terminal (or a new tab) to see it.")


if __name__ == "__main__":
    main()
