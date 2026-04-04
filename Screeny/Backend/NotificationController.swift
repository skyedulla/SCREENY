//
//  NotificationController.swift
//  Screeny
//
//  UserNotifications / UNUserNotificationCenter with a stable identifier so updates replace a pending request.
//

import Foundation
import UserNotifications

/// Not `@MainActor`: `UNUserNotificationCenter` calls the delegate and `add` completion handlers off the main thread;
/// isolating this type on MainActor caused Swift runtime data-race warnings.
final class NotificationController: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let idleAlertIdentifier = "idle_alert"

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Refreshes the idle alert with whole-second idle duration. Call each poll while idle stays above threshold.
    /// Replaces pending + delivered so the banner updates instead of stacking. Sound only on `playSound`.
    func refreshIdleAlert(idleSeconds: Double, playSound: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.idleAlertIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.idleAlertIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Cursor idle"
        let secs = Int(idleSeconds.rounded(.down))
        content.body = "Cursor idle for \(secs) seconds"
        content.sound = playSound ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: Self.idleAlertIdentifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                #if DEBUG
                print("Screeny: idle notification failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Removes the delivered banner/alert once the user moves the cursor again.
    func dismissIdleAlert() {
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [Self.idleAlertIdentifier])
        center.removePendingNotificationRequests(withIdentifiers: [Self.idleAlertIdentifier])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.identifier == Self.idleAlertIdentifier,
           notification.request.content.sound == nil {
            return [.banner]
        }
        return [.banner, .sound]
    }
}
