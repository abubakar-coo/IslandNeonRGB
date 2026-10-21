import SwiftUI

/// Plain-language record of what was investigated and why the exact target is out of reach.
struct LimitationsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("The target") {
                    Text("A permanently visible RGB outline immediately outside the real Dynamic Island, including while other apps are open.")
                }

                Section("Verdict") {
                    Text("Not achievable with public iOS APIs. The pixels around the cutout belong to whichever app is in the foreground, or to the system. A third-party app has no sanctioned way to draw there while another app is active, and this project does not claim otherwise.")
                        .fontWeight(.medium)
                }

                Section("Approaches checked") {
                    approach("App windows / UIWindow levels", verdict: "No",
                             detail: "A window exists only while its app is in the foreground. iOS has no system-wide overlay window level for third-party apps; the \"draw over other apps\" permission is an Android concept.")
                    approach("Live Activities (ActivityKit)", verdict: "Partial, used here",
                             detail: "Sanctioned and visible over other apps, but the UI is a static snapshot inside the island's own presentation. keylineTint is a single colour, animations are ignored, updates are budgeted, and the activity ends after 8 hours.")
                    approach("Home / Lock Screen widgets", verdict: "No",
                             detail: "Fixed slots, static rendering, nowhere near the cutout.")
                    approach("Picture in Picture", verdict: "No",
                             detail: "A floating video player the user can move; it cannot be pinned around the island and misusing it for overlays is rejected by App Review.")
                    approach("Background execution", verdict: "No",
                             detail: "Background modes allow audio, location, processing and similar work; none allow drawing on screen while suspended.")
                    approach("Accessibility, Guided Access, MDM", verdict: "No",
                             detail: "None expose screen drawing to third-party apps.")
                    approach("Private APIs or jailbreak tweaks", verdict: "Out of scope",
                             detail: "Tweaks that restyle the island exist, but they rely on a jailbreak and private frameworks, which this project rules out.")
                }

                Section("What this prototype does instead") {
                    bullet("Immersive mode draws the animated outline around the real cutout, aligned with calibratable geometry, while this app is in the foreground.")
                    bullet("A real Live Activity with compact, minimal and expanded presentations. Its keyline tint steps through the chosen palette on each update, so the island's border visibly changes colour over other apps, within ActivityKit's rules.")
                    bullet("Every dimension is configurable and the detected device is shown, rather than hard-coding one phone.")
                }

                Section("Sources") {
                    Text("Apple: DynamicIsland.keylineTint(_:) applies \"a subtle tint color to the surrounding border of a Live Activity that appears in the Dynamic Island\" (iOS 16.1+).")
                    Text("Apple: \"Displaying live data with Live Activities\" states that animation modifiers are ignored, that activities last at most 8 hours, and that update payloads are limited to 4 KB.")
                }
                .font(.footnote)
            }
            .navigationTitle("Limits")
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
        }
    }

    private func approach(_ name: String, verdict: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).fontWeight(.semibold)
                Spacer()
                Text(verdict)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1), in: Capsule())
            }
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

#Preview {
    LimitationsView()
        .preferredColorScheme(.dark)
}
