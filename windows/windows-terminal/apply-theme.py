#!/usr/bin/env python3
"""Aplica um tema do Windows Terminal a ESTA máquina, por %COMPUTERNAME%.

Ao contrário de copiar o settings.json por cima (que quebraria o defaultProfile
e apagaria profiles específicos da máquina — Ubuntu, Visual Studio, etc.), este
script MESCLA:

  settings.base.json  (prefs compartilhadas: keybindings, defaults cosméticos)
  + themes.json       (o tema escolhido: colorScheme do WSL/PowerShell, fonte, opacidade + todas as paletas)
  + machines.json     (qual tema esta máquina usa, por COMPUTERNAME)

dentro do settings.json que o Windows Terminal realmente usa, preservando a
lista de profiles (GUIDs) e o defaultProfile da máquina.

Uso:
  ./apply-theme.py                 # tema da máquina atual (machines.json)
  ./apply-theme.py rose-pine       # força um tema específico
  ./apply-theme.py --dry-run       # mostra o que mudaria, sem gravar
  ./apply-theme.py --list          # lista os temas disponíveis
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
    # tolera as chaves "//" de comentário e mantém a ordem
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def computername():
    """%COMPUTERNAME% do Windows, visto de dentro do WSL."""
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
    """Caminho (WSL) do settings.json do Windows Terminal."""
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
    # 1) prefs compartilhadas de topo (sem tocar em profiles/defaultProfile/schemes)
    for key in ("copyFormatting", "copyOnSelect", "keybindings",
                "newTabMenu", "theme", "useAcrylicInTabRow"):
        if key in base:
            settings[key] = base[key]

    # 2) defaults = cosméticos compartilhados + tema (colorScheme do WSL, fonte, opacidade)
    defaults = settings.setdefault("profiles", {}).setdefault("defaults", {})
    defaults.update(base.get("defaults", {}))
    defaults["colorScheme"] = theme["wslScheme"]
    defaults["opacity"] = theme["opacity"]
    defaults["font"] = {"face": theme["font"], "size": theme["fontSize"]}

    # 3) cada profile PowerShell recebe o esquema/fonte do shell
    shell_font = theme.get("shellFont", theme["font"])
    for prof in settings.get("profiles", {}).get("list", []):
        if is_powershell(prof):
            prof["colorScheme"] = theme["shellScheme"]
            prof["font"] = {"face": shell_font, "size": theme["fontSize"]}


def main():
    ap = argparse.ArgumentParser(description="Aplica um tema do Windows Terminal por máquina.")
    ap.add_argument("theme", nargs="?", help="Força um tema (senão usa machines.json).")
    ap.add_argument("--dry-run", action="store_true", help="Mostra o resultado sem gravar.")
    ap.add_argument("--list", action="store_true", help="Lista os temas disponíveis.")
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
        sys.exit(f"tema desconhecido: {theme_name!r} (veja --list)")
    theme = themes[theme_name]

    settings_path = win_settings_path()
    if not settings_path.is_file():
        sys.exit(f"settings.json do Windows Terminal não encontrado: {settings_path}")

    settings = load_json(settings_path)

    upsert_schemes(settings, themes_doc["schemes"])
    apply(settings, base, theme)

    rendered = json.dumps(settings, indent=4, ensure_ascii=False)

    print(f"máquina     : {host}")
    print(f"tema        : {theme_name}")
    print(f"WSL         : {theme['wslScheme']}  ·  fonte {theme['font']} {theme['fontSize']}  ·  opacidade {theme['opacity']}")
    print(f"PowerShell  : {theme['shellScheme']}  ·  fonte {theme.get('shellFont', theme['font'])}")
    print(f"settings    : {settings_path}")

    if args.dry_run:
        print("\n--dry-run: nada gravado.")
        return

    backup = settings_path.with_suffix(".json.bak")
    shutil.copy2(settings_path, backup)
    settings_path.write_text(rendered + "\n", encoding="utf-8")
    print(f"\n✓ aplicado. backup em {backup}")
    print("  Reabra o Windows Terminal (ou uma nova aba) para ver.")


if __name__ == "__main__":
    main()
