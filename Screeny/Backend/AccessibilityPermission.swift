//
//  AccessibilityPermission.swift
//  Screeny
//
//  Prompts System Settings → Privacy & Security → Accessibility as in the flowchart.
//

import ApplicationServices
import Foundation

enum AccessibilityPermission {
    static func promptIfNeeded() {
        // String key matches kAXTrustedCheckOptionPrompt; avoids Swift 6 concurrency issues on the global var.
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options: NSDictionary = [promptKey: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }
}
