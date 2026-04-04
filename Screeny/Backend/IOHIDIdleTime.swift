//
//  IOHIDIdleTime.swift
//  Screeny
//
//  Seconds since last keyboard/pointer input via Quartz (`CGEventSource`).
//  Apple documents `secondsSinceLastEventType` with `kCGAnyInputEventType` for “previous input event—keyboard,
//  mouse, or tablet.” Using `kCGEventNull` (rawValue 0) is incorrect: it does not track user idle and can climb
//  without reflecting pointer/keyboard activity.
//

import CoreGraphics
import Foundation

enum IOHIDIdleTime {
    /// `kCGAnyInputEventType` — `(CGEventType)(~0)`; not a named Swift `CGEventType` case.
    private static let anyInputEventType = CGEventType(rawValue: UInt32.max)!

    /// Elapsed time since last HID activity, in seconds.
    static func seconds() -> Double? {
        let t = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: Self.anyInputEventType)
        guard t >= 0, t.isFinite else { return nil }
        return t
    }
}
