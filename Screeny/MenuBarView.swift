//
//  MenuBarView.swift
//  Screeny
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var idleMonitor: IdleMonitor
    /// Persisted so launch + `IdleMonitor` bootstrap agree; default on so idle alerts run without opening the menu first.
    @AppStorage(IdleMonitor.workSessionUserDefaultsKey) private var isWorkSessionActive = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Screeny")
                .font(.headline)
            Text("You’ll get a notification after 15 seconds without cursor movement. The menu is only for settings and quitting.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // TEMP: remove after idle + notification test
            Group {
                Divider()
                Text("Idle debug (remove later)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let idle = idleMonitor.lastIdleSeconds {
                    LabeledContent("HID idle") {
                        Text(String(format: "%.2f s", idle)).monospacedDigit()
                    }
                    .font(.caption)
                    LabeledContent("Countdown to alert") {
                        Text(String(format: "%.2f s", max(0, IdleMonitor.idleThresholdSeconds - idle))).monospacedDigit()
                    }
                    .font(.caption)
                } else {
                    Text("No samples (work session off)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Button {
                isWorkSessionActive.toggle()
            } label: {
                Text(isWorkSessionActive ? "End Work Session" : "Start Work Session")
            }
            .buttonStyle(.borderless)

            Divider()

            LabeledContent("Accessibility") {
                Text(idleMonitor.isAccessibilityTrusted ? "Granted" : "Not granted")
                    .foregroundStyle(idleMonitor.isAccessibilityTrusted ? .green : .orange)
            }
            .font(.caption)

            if !idleMonitor.isAccessibilityTrusted {
                Text(
                    "If the toggle is on but this still says “Not granted,” your Xcode build likely isn’t signed with a Development Team—each rebuild can look like a different app to macOS. Set a Team under Signing & Capabilities, or in Terminal run: tccutil reset Accessibility \(Bundle.main.bundleIdentifier ?? "com.screeny.Screeny")"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Button("Open Accessibility Settings…") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderless)

            Divider()

            Button("Quit Screeny") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(minWidth: 280)
        .onAppear {
            idleMonitor.refreshAccessibilityStatus()
        }
        .onChange(of: isWorkSessionActive) { _, active in
            if active {
                idleMonitor.start()
            } else {
                idleMonitor.stop()
            }
        }
    }
}
