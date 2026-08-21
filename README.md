# SCREENY v1.0
A MacOS Menu Bar Application

Purpose: The Application is designed to be used during Work Sessions. You simply navigate and hover over the app icon in your menu bar and press "Start Work Session". While a Work Session is ongoing,
your OS will push a notification if you haven't moved your touchpad/mouse/keyboard for 15 seconds. This application is designed to be a supplement for coding, writing, and highly interactive work for users
with focus & concentration problems. 


Tech Stack: Built with Swift and SwiftUI for a native macOS menu bar interface. Low-level system activity is tracked using CoreGraphics (CGEventSource) alongside macOS Accessibility APIs (AXIsProcessTrusted) to detect hardware idle time. Local desktop notifications are handled via the UserNotifications framework, integrated with AppKit for application lifecycle management.
