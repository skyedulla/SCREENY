//
//  IdleMonitor.swift
//  Screeny
//
//  Polls HID idle time once per second and drives notification state at a 15s threshold.
//

import AppKit
import Combine
import Foundation

@MainActor
final class IdleMonitor: ObservableObject {
    static let idleThresholdSeconds: Double = 15
    private static let pollInterval: TimeInterval = 1
    private static let accessibilityPollInterval: TimeInterval = 2
    /// Treat HID idle below this as “user active” so the alert clears after movement.
    private static let activeThresholdSeconds: Double = 0.2
    /// Must match `MenuBarView` `@AppStorage` key for “Start Work Session”.
    static let workSessionUserDefaultsKey = "Screeny.workSessionActive"

    private var isIdleAlertActive = false

    private var timer: Timer?
    private var accessibilityPollTimer: Timer?
    private let notifications = NotificationController()
    /// Observer token; touched from MainActor and `deinit` (nonisolated), hence `unsafe`.
    nonisolated(unsafe) private var didFinishLaunchingObserver: NSObjectProtocol?

    /// Mirrors `AXIsProcessTrusted()` so SwiftUI updates after the user changes Accessibility in System Settings.
    @Published private(set) var isAccessibilityTrusted = AccessibilityPermission.isTrusted
    /// Latest HID idle read (updated each poll while the work session timer runs). For temporary UI debugging.
    @Published private(set) var lastIdleSeconds: Double?

    init() {
        accessibilityPollTimer = Timer.scheduledTimer(withTimeInterval: Self.accessibilityPollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAccessibilityStatus()
            }
        }
        if let accessibilityPollTimer {
            RunLoop.main.add(accessibilityPollTimer, forMode: .common)
        }
        // AXIsProcessTrusted can read false for a moment at launch; re-check after AppKit settles.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.refreshAccessibilityStatus()
        }

        // `MenuBarExtra` content (and its `.task`) can load lazily; notification auth + idle polling must run at launch.
        didFinishLaunchingObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.bootstrapAfterLaunch()
            }
        }
    }

    deinit {
        if let didFinishLaunchingObserver {
            NotificationCenter.default.removeObserver(didFinishLaunchingObserver)
        }
    }

    /// `nil` key → treat as on (matches SwiftUI `@AppStorage` default).
    static func isWorkSessionEnabledInDefaults() -> Bool {
        if UserDefaults.standard.object(forKey: workSessionUserDefaultsKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: workSessionUserDefaultsKey)
    }

    private func bootstrapAfterLaunch() async {
        await prepareNotifications()
        if Self.isWorkSessionEnabledInDefaults() {
            start()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.promptAccessibility()
        }
    }

    func refreshAccessibilityStatus() {
        let trusted = AccessibilityPermission.isTrusted
        if trusted != isAccessibilityTrusted {
            isAccessibilityTrusted = trusted
        }
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastIdleSeconds = nil
        if isIdleAlertActive {
            isIdleAlertActive = false
            notifications.dismissIdleAlert()
        }
    }

    func prepareNotifications() async {
        _ = await notifications.requestAuthorization()
    }

    func promptAccessibility() {
        AccessibilityPermission.promptIfNeeded()
        refreshAccessibilityStatus()
    }

    private func tick() {
        let idle = IOHIDIdleTime.seconds() ?? 0
        lastIdleSeconds = idle

        if idle >= Self.idleThresholdSeconds {
            let firstPresentation = !isIdleAlertActive
            if firstPresentation {
                isIdleAlertActive = true
            }
            notifications.refreshIdleAlert(idleSeconds: idle, playSound: firstPresentation)
        } else if idle <= Self.activeThresholdSeconds {
            if isIdleAlertActive {
                isIdleAlertActive = false
                notifications.dismissIdleAlert()
            }
        }
    }
}
