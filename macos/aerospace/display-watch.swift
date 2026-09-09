// display-watch — run a command whenever a display is connected or disconnected.
//
// This exists because nothing else on the machine will do it:
//
//   * launchd has no trigger for display changes. WatchPaths watches files, and
//     the display layout is not a file.
//   * AeroSpace 0.21.3 has exactly three callbacks — on-focus-changed,
//     on-focused-monitor-changed and on-window-detected. None of them fires
//     when a panel appears or goes away. (Checked against the binary's own
//     config keys; do not assume a newer version still lacks one.)
//
// So the layout stayed on whatever apply-layout.py last wrote, and opening or
// closing the MacBook lid silently left the wrong one applied: the two-screen
// layout on three panels leaves a screen with no workspace, and the
// three-screen layout on two hides a third of them behind the others.
//
//   Build:  swiftc -O display-watch.swift -o display-watch
//   Run:    ./display-watch ~/.config/aerospace/apply-layout.py
//
// Any command works — it is not AeroSpace-specific. Installed as a LaunchAgent
// by macos/bootstrap.sh (step `displaywatch`).

import CoreGraphics
import Dispatch
import Foundation

let argv = CommandLine.arguments
guard argv.count > 1 else {
    FileHandle.standardError.write(Data("usage: display-watch <command> [args…]\n".utf8))
    exit(2)
}
let command = argv[1]
let commandArgs = Array(argv.dropFirst(2))

// A single plug or unplug produces a BURST of callbacks — one per display, plus
// a begin/end pair wrapping the whole reconfiguration. Acting on each would
// reload AeroSpace half a dozen times for one lid close, so the run is deferred
// and re-deferred until the burst stops.
//
// The delay does a second job that matters more: apply-layout.py counts
// monitors by asking AeroSpace, and AeroSpace needs a moment after a
// reconfiguration to agree with CoreGraphics. Firing immediately reads the OLD
// count and applies exactly the wrong layout.
let eventDebounce = 3.0

// The run at launch is a separate, longer wait. At login this agent and
// AeroSpace start at roughly the same time, and apply-layout.py exits with an
// error if the AeroSpace server is not answering yet. Ten seconds is slack for
// that race, not tuning.
let startupDelay = 10.0

// One serial queue owns `pending`, so the CoreGraphics callback (which arrives
// on the main run loop) never races the work item that fires the command.
let queue = DispatchQueue(label: "display-watch")
var pending: DispatchWorkItem?

func scheduleRun(after delay: Double) {
    pending?.cancel()
    let work = DispatchWorkItem {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = commandArgs
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            FileHandle.standardError.write(Data("display-watch: \(command): \(error)\n".utf8))
        }
    }
    pending = work
    queue.asyncAfter(deadline: .now() + delay, execute: work)
}

let onReconfigure: CGDisplayReconfigurationCallBack = { _, flags, _ in
    // beginConfigurationFlag is the "about to change" notice. It carries no
    // information about the outcome, and the matching "it changed" callback
    // always follows, so acting on it would only fire the debounce early.
    if flags.contains(.beginConfigurationFlag) { return }

    // setModeFlag is deliberately absent from this list. Changing a resolution
    // or refresh rate cannot change the monitor COUNT, so it cannot change
    // which layout applies — and reacting to it would make every BetterDisplay
    // tweak reload AeroSpace.
    guard flags.contains(.addFlag) || flags.contains(.removeFlag)
        || flags.contains(.enabledFlag) || flags.contains(.disabledFlag)
    else { return }

    queue.async { scheduleRun(after: eventDebounce) }
}

CGDisplayRegisterReconfigurationCallback(onReconfigure, nil)
queue.async { scheduleRun(after: startupDelay) }
CFRunLoopRun()
