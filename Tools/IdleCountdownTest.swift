//
//  Terminal harness: mirrors Screeny’s idle readout (CGEventSource + 15s threshold, 1s poll).
//  Build: swiftc -o idle_countdown IdleCountdownTest.swift -framework CoreGraphics -framework Foundation
//

import CoreGraphics
import Foundation

private let idleThresholdSeconds: Double = 15
private let pollInterval: TimeInterval = 1
private let activeThresholdSeconds: Double = 0.2

private func idleSeconds() -> Double? {
    // kCGAnyInputEventType — see Apple docs for secondsSinceLastEventType(_:eventType:)
    let anyInput = CGEventType(rawValue: UInt32.max)!
    let t = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInput)
    guard t >= 0, t.isFinite else { return nil }
    return t
}

private func pad(_ s: String, width: Int) -> String {
    if s.count >= width { return String(s.prefix(width)) }
    return s + String(repeating: " ", count: width - s.count)
}

setbuf(__stdoutp, nil)

print("Idle countdown (same HID + thresholds as IdleMonitor). Move mouse/keys to reset.")
print("poll \(pollInterval)s | idle≥\(Int(idleThresholdSeconds))s → notify | idle≤\(activeThresholdSeconds)s → clear")
print(String(repeating: "-", count: 72))
print("")

var lastLine = ""

while true {
    let idle = idleSeconds()

    if let idle {
        let remaining = max(0, idleThresholdSeconds - idle)
        let state: String
        if idle >= idleThresholdSeconds {
            state = "THRESHOLD (would present notification)"
        } else if idle <= activeThresholdSeconds {
            state = "active band (would dismiss)"
        } else {
            state = "counting"
        }

        let line =
            "HID idle: \(String(format: "%.2f", idle))s  |  "
            + "countdown to \(Int(idleThresholdSeconds))s: \(String(format: "%.2f", remaining))s  |  "
            + state

        let padded = pad(line, width: max(line.count, lastLine.count))
        print("\r\(padded)", terminator: "")
        lastLine = line
    } else {
        let msg = "HID idle: <nil> (cannot read secondsSinceLastEventType)"
        let padded = pad(msg, width: max(msg.count, lastLine.count))
        print("\r\(padded)", terminator: "")
        lastLine = msg
    }

    fflush(stdout)
    Thread.sleep(forTimeInterval: pollInterval)
}
