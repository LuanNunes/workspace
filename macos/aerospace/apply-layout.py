#!/usr/bin/env python3
"""Merge aerospace.base.toml with a layout fragment and reload AeroSpace.

The AeroSpace config format has no `include`, so a two-monitor and a
three-monitor setup would otherwise be two ~300-line files differing in about
forty — and two copies drift. This keeps one base and small fragments, the same
arrangement windows/windows-terminal/apply-theme.py uses for its themes.

    ./apply-layout.py            detect screen count and apply the match
    ./apply-layout.py 2mon       force a layout
    ./apply-layout.py --dry-run  print what would change, write nothing
    ./apply-layout.py --no-rehome  switch layouts but leave open windows alone

Switching layouts re-homes the windows that are already open, because
`on-window-detected` rules fire only when a window is BORN. Without this, an app
opened under one layout keeps the workspace that layout gave it: Safari opened
with the lid up landed on ws 8, and closing the lid left it there — on a
workspace the two-screen layout does not even bind a key for, so it was
invisible AND unreachable from the keyboard.

Re-homing runs ONLY when the layout actually changed, so re-running this script
never overrides where you deliberately put something.

The generated aerospace.toml is git-ignored: it is an artifact, and the sources
are base + fragment. bootstrap.sh runs this before symlinking.
"""
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
BASE = HERE / "aerospace.base.toml"
OUT = HERE / "aerospace.toml"
AEROSPACE = "/opt/homebrew/bin/aerospace"
SECTIONS = ("PERSISTENT_WORKSPACES", "MONITOR_ASSIGNMENT", "WORKSPACE_BINDINGS", "APP_RULES")


def die(msg):
    print(f"apply-layout: {msg}", file=sys.stderr)
    sys.exit(1)


def count_monitors():
    """Ask AeroSpace, not the OS: it is the thing whose view has to match."""
    try:
        out = subprocess.run([AEROSPACE, "list-monitors"], capture_output=True,
                             text=True, timeout=10)
    except (OSError, subprocess.SubprocessError) as e:
        die(f"could not ask AeroSpace how many monitors it sees ({e}). "
            f"Pass a layout explicitly, e.g. 'apply-layout.py 2mon'.")
    if out.returncode != 0:
        die(f"aerospace list-monitors failed: {out.stderr.strip()}")
    return len([l for l in out.stdout.splitlines() if l.strip()])


def parse_fragment(path):
    """Split a fragment on its `# ---8<--- NAME` markers."""
    text = path.read_text()
    parts, name, buf = {}, None, []
    for line in text.split("\n"):
        m = re.match(r"^#\s*-+8<-+\s*([A-Z_]+)\s*$", line)
        if m:
            if name:
                parts[name] = "\n".join(buf).strip("\n")
            name, buf = m.group(1), []
        elif name:
            buf.append(line)
    if name:
        parts[name] = "\n".join(buf).strip("\n")
    missing = [s for s in SECTIONS if s not in parts]
    if missing:
        die(f"{path.name} is missing section(s): {', '.join(missing)}")
    return parts


def rehome_windows(app_rules):
    """Move already-open windows to the workspace the NEW layout gives them.

    AeroSpace applies `on-window-detected` when a window is created and never
    again, so a layout switch leaves every open window on the workspace the
    previous layout chose. Ask the config what each app should get, ask
    AeroSpace where each window actually is, and reconcile the difference.

    Deliberately WITHOUT --focus-follows-window: the rules use it so that
    opening an app takes you to it, but here a dozen windows may move at once
    and following each one would leave focus somewhere random.
    """
    wanted = dict(re.findall(
        r"if\.app-id\s*=\s*'([^']+)'.*?run\s*=\s*'move-node-to-workspace\s+(\d+)",
        app_rules))
    if not wanted:
        return

    out = subprocess.run(
        [AEROSPACE, "list-windows", "--all",
         "--format", "%{window-id} %{app-bundle-id} %{workspace}"],
        capture_output=True, text=True)
    if out.returncode != 0:
        print(f"apply-layout: could not list windows, skipping re-home: "
              f"{out.stderr.strip()}", file=sys.stderr)
        return

    moved = 0
    for line in out.stdout.splitlines():
        parts = line.split()
        if len(parts) != 3:
            continue
        win_id, app_id, current = parts
        target = wanted.get(app_id)
        if target is None or target == current:
            continue
        r = subprocess.run([AEROSPACE, "move-node-to-workspace", target,
                            "--window-id", win_id],
                           capture_output=True, text=True)
        if r.returncode == 0:
            print(f"apply-layout: {app_id} {current} -> {target}")
            moved += 1
        else:
            # Not fatal: a window can close between the list and the move, and
            # one app refusing to move is no reason to strand the rest.
            print(f"apply-layout: could not move {app_id} ({win_id}): "
                  f"{r.stderr.strip()}", file=sys.stderr)
    if not moved:
        print("apply-layout: no windows needed re-homing")


def main():
    args = [a for a in sys.argv[1:]
            if a not in ("--dry-run", "--no-rehome")]
    dry = "--dry-run" in sys.argv[1:]
    rehome = "--no-rehome" not in sys.argv[1:]

    if args:
        layout = args[0]
    else:
        n = count_monitors()
        # Everything that is not three screens gets the two-column layout: on a
        # single display the pair layout degrades to six workspaces on one
        # screen, which is right, while the three-column one hides a third of
        # them behind the others.
        layout = "3mon" if n >= 3 else "2mon"
        print(f"apply-layout: {n} monitor(s) -> {layout}")

    frag = HERE / f"layout-{layout}.toml"
    if not frag.exists():
        avail = ", ".join(sorted(p.stem.replace("layout-", "")
                                 for p in HERE.glob("layout-*.toml")))
        die(f"no layout '{layout}' (have: {avail})")

    parts = parse_fragment(frag)
    merged = BASE.read_text()
    for section in SECTIONS:
        token = f"@@{section}@@"
        if token not in merged:
            die(f"{BASE.name} has no {token} placeholder")
        merged = merged.replace(token, parts[section], 1)
    if "@@" in merged:
        die("a placeholder survived the merge — check the base file")

    merged = merged.replace(
        "# AeroSpace BASE — everything that does not depend on how many screens are",
        f"# GENERATED by apply-layout.py from aerospace.base.toml + layout-{layout}.toml.\n"
        f"# Do not edit this file — edit those two and re-run the script.\n"
        f"#\n"
        f"# AeroSpace BASE — everything that does not depend on how many screens are", 1)

    # Whether the LAYOUT changed, not whether this script ran. The generated
    # file carries the fragment's name in its header, so identical content means
    # the same layout merged from the same sources — and that is the signal for
    # whether open windows should be re-homed. Re-homing on every invocation
    # would silently undo any window you had moved by hand.
    changed = (not OUT.exists()) or OUT.read_text() != merged

    if dry:
        print(f"apply-layout: would write {OUT} from layout-{layout} "
              f"({len(merged.splitlines())} lines)")
        if changed and rehome:
            print("apply-layout: would re-home open windows (layout changed)")
        elif not changed:
            print("apply-layout: layout unchanged, would leave windows alone")
        return

    OUT.write_text(merged)
    print(f"apply-layout: wrote {OUT.name} from layout-{layout}")

    check = subprocess.run([AEROSPACE, "reload-config", "--dry-run"],
                           capture_output=True, text=True)
    if check.returncode != 0 or "ERROR" in (check.stdout + check.stderr):
        die("the merged config does not parse — NOT reloading:\n"
            + (check.stdout + check.stderr).strip())
    subprocess.run([AEROSPACE, "reload-config"], check=False)
    print("apply-layout: reloaded")

    if changed and rehome:
        rehome_windows(parts["APP_RULES"])


if __name__ == "__main__":
    main()
