//
//  ScreenyApp.swift
//  Screeny
//
//  SwiftUI menu bar shell (Swift 6+).
//

import AppKit
import SwiftUI

@main
struct ScreenyApp: App {
    @StateObject private var idleMonitor = IdleMonitor()

    var body: some Scene {
        MenuBarExtra("Screeny", systemImage: "cursorarrow") {
            MenuBarView(idleMonitor: idleMonitor)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    idleMonitor.refreshAccessibilityStatus()
                }
        }
    }
}
