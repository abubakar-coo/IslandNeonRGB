# Can a third-party app draw a permanent RGB outline around the Dynamic Island?

**Target:** a permanently visible RGB outline immediately outside the real Dynamic Island,
including while other apps are open, using only public iOS APIs.

**Answer: no.** Below is each public mechanism that could conceivably draw near the cutout,
and why it does not meet the target. The prototype in this repository implements the closest
sanctioned behaviour and labels it as such.

## Why the target is out of reach

The Dynamic Island cutout is a hole in the display for the camera and Face ID module. The
black "pill" users see is the cutout itself plus the system's animated black shape around it.
The pixels surrounding it are ordinary screen pixels owned, at any moment, by exactly one of:

* the foreground app's windows, or
* the system (Springboard, the Lock Screen, Live Activity and notification surfaces).

iOS has no equivalent of Android's "draw over other apps" permission. There is no public
window level, overlay entitlement or background mode that lets one app paint on top of
another. Everything below follows from that.

## Mechanisms checked

| Mechanism | Verdict | Why |
|---|---|---|
| `UIWindow` with a high `windowLevel` | No | Windows belong to the app's scene and are visible only while the app is in the foreground. They are torn down on backgrounding. |
| Multiple scenes / `UIScene` tricks | No | Same ownership rule; a scene is still the app's. |
| **Live Activities (ActivityKit + WidgetKit)** | Partial, **used here** | The only sanctioned way to put app content in the island over other apps. But: the UI is a static snapshot rendered by WidgetKit; `withAnimation`, `.animation` and `TimelineView` are ignored; content is confined to the island's compact/minimal/expanded regions and never drawn *outside* the island; `keylineTint` accepts a single `Color`; updates are rate-limited by a per-device budget; the activity ends after 8 hours. |
| `DynamicIsland.keylineTint(_:)` | Partial | Apple: "Applies a subtle tint color to the surrounding border of a Live Activity that appears in the Dynamic Island." It colours the border the system draws around the Live Activity presentation. One colour, static, system-controlled width and visibility, and only while the activity is shown. This project cycles it through the palette on each update. |
| ActivityKit push updates | Partial | Lets a server update the activity while the app is suspended, which this prototype does not include. Updates still draw on the same budget; a 60 fps rainbow is many orders of magnitude outside it. |
| Home Screen / Lock Screen widgets | No | Fixed slots far from the cutout, static rendering, refreshed on a system timeline. |
| Picture in Picture | No | A floating video layer the user can move and dismiss. It is not pinned to the island and using it as a decorative overlay is rejected by App Review. |
| Background modes (audio, location, processing, VoIP, etc.) | No | They keep code running; none give drawing access to the screen. |
| Accessibility features, Guided Access, Screen Time | No | System-owned; no third-party drawing hooks. |
| MDM / supervised device profiles | No | Can restrict features, cannot inject UI. |
| Custom wallpaper | Partial, out of scope | A static wallpaper image could place a coloured ring around the cutout on the Home and Lock Screens only. Not animated, not visible inside other apps, and an image file rather than code. |
| Private APIs, jailbreak tweaks | Out of scope | Tweaks that restyle the island exist (e.g. island-customisation tweaks for jailbroken devices). They need a jailbreak and private frameworks; not allowed by the brief or the App Store. |

## What the prototype does

1. **In-app, around the real cutout.** `ImmersiveIslandView` hides the status bar, extends
   under the safe area and draws the animated outline at the configured island geometry. While
   Island Neon is in the foreground this *is* a real RGB outline around the real cutout. The
   moment another app comes forward it is gone.
2. **Over other apps, within ActivityKit's rules.** `NeonActivityManager` starts a Live
   Activity and, while the app is in the foreground, sends a new `ContentState` every few
   seconds. `IslandNeonLiveActivity` sets `keylineTint` and all accents from that state, so the
   border iOS draws around the island steps through the palette. No gradient, no continuous
   motion, one colour per update, and it stops when the app is suspended.
3. **Geometry is data, not assumptions.** `IslandGeometry` carries width, height, top inset,
   horizontal offset and corner radius. The defaults (126 × 37.33 pt, 11 pt from the top,
   capsule corners) come from Apple's design resources for the 14/15/16 Pro family, which share
   the same module. There is no public API that reports the cutout frame, so the immersive
   screen includes calibration sliders and the detected device is shown in Settings.

## Sources

* Apple Developer Documentation, `DynamicIsland.keylineTint(_:)` (WidgetKit, iOS 16.1+).
* Apple Developer Documentation, "Displaying live data with Live Activities" (ActivityKit):
  animation modifiers ignored, 8-hour maximum, 4 KB payload limit, sandboxed rendering.
* Apple Developer Forums threads on Live Activity update budgets and
  `NSSupportsLiveActivitiesFrequentUpdates`.
