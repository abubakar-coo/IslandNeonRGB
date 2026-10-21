# IslandNeonRGB

A premium RGB neon-outline concept for Apple's Dynamic Island, built with Swift, SwiftUI,
WidgetKit and ActivityKit. Target device: iPhone 16 Pro Max (iOS 17+, Xcode 16).

## The honest headline

**The exact target, a permanently visible RGB outline around the real Dynamic Island while
other apps are open, cannot be built with public iOS APIs.** The pixels around the cutout
belong to the foreground app or to the system; no third-party app can draw there while
another app is active. [docs/LIMITATIONS.md](docs/LIMITATIONS.md) lists every approach
that was checked and why each one fails.

What this project ships instead, without pretending otherwise:

| Piece | What it really does |
|---|---|
| **Animated island mockup** | A pill matching the 16 Pro Max island proportions with a perimeter-accurate travelling RGB stroke, outer glow, brightness, speed, direction and six colour modes. Rendered with `Canvas` + `TimelineView`. |
| **Immersive alignment mode** | Draws that stroke around the *real* cutout, calibrated with on-device sliders. Visible only while this app is in the foreground. |
| **Real Live Activity** | ActivityKit activity with compact, minimal, expanded and Lock Screen presentations. `DynamicIsland.keylineTint` is set from the content state and the app steps it through the palette on every update, so the border iOS draws around the island visibly changes colour over other apps. One solid colour per update, no gradient, no animation, 8-hour cap. |
| **Settings** | Live preview on a to-scale phone, colour modes, animation, stroke and glow, island geometry with device presets and auto-detection, Live Activity cadence. |
| **Limits tab** | The investigation, in the app itself. |

## Layout

```
IslandNeonRGB.xcodeproj/          Xcode 16 project (file-system-synchronized groups)
project.yml                       XcodeGen fallback that generates an equivalent project
IslandNeonRGB/                    App target
  IslandNeonRGBApp.swift          Entry point; wires settings + activity manager
  Info.plist                      NSSupportsLiveActivities, FrequentUpdates, URL scheme
  IslandNeonRGB.entitlements      Empty; nothing extra is needed for local Live Activities
  Models/IslandGeometry.swift     Island dimensions + device presets + screen-size matching
  Models/NeonSettings.swift       NeonConfig (persisted) + @Observable settings store
  Views/NeonOutlineView.swift     Canvas renderer: perimeter-distributed gradient stroke + glow
  Views/NeonIslandView.swift      Black pill + outline, driven by TimelineView
  Views/ContentView.swift         Tabs, home screen, mode picker, LabeledSlider
  Views/PhoneMockupPreview.swift  To-scale phone top for the settings preview
  Views/ImmersiveIslandView.swift Full-screen alignment mode with calibration sliders
  Views/SettingsView.swift        All controls
  Views/LiveActivityView.swift    Start/stop/cycle the Live Activity, status, caveats
  Views/LimitationsView.swift     Investigation summary
  LiveActivity/NeonActivityManager.swift  ActivityKit start / update / end / observe
IslandNeonWidget/                 Widget extension target (hosts the Live Activity UI)
  IslandNeonWidgetBundle.swift
  IslandNeonLiveActivity.swift    DynamicIsland presentations + keylineTint + Lock Screen view
  Info.plist                      NSExtensionPointIdentifier = com.apple.widgetkit-extension
Shared/                           Compiled into both targets
  NeonColorMode.swift             HSBColor + six colour loops with interpolation
  NeonActivityAttributes.swift    ActivityAttributes / ContentState
docs/BUILD.md                     Build, signing and on-device test steps
docs/LIMITATIONS.md               Full investigation of the "over other apps" requirement
tools/validate_project.py         Static checks (pbxproj references, plist/JSON, brace balance)
```

Run the static checks from the repository root with:

```bash
python3 tools/validate_project.py .
```

## Build

See [docs/BUILD.md](docs/BUILD.md). Short version: open `IslandNeonRGB.xcodeproj` in
Xcode 16 on macOS, set your team on both targets, run on an iPhone with a Dynamic Island.

> This project was authored on Windows, where Xcode is unavailable, so it has **not** been
> compiled. Project structure and sources were validated statically (object references,
> plist/JSON well-formedness, brace balance). The first Xcode build is the real test; any
> errors it reports should be small and local.

## Design notes

* **Perimeter-accurate gradient.** An `AngularGradient` on a wide pill bunches colour at
  the rounded ends. `NeonOutlineView` instead trims the outline path into `segments`
  pieces and colours each by its distance along the perimeter, so the rainbow travels at a
  constant speed along the flat edges.
* **No hard-coded phone.** `IslandGeometry` holds width, height, top inset, horizontal
  offset and corner radius. `DevicePreset.matching(screenSize:)` picks a preset from the
  window size, and auto-detection never overwrites manual calibration.
* **Reduce Motion** pauses the animation; speed 0 freezes it.
* **Live Activity colour cycling** is a foreground `Task` loop calling `Activity.update`.
  Each update is a new `ContentState` carrying the next `HSBColor`; the widget derives
  gradients, the dot and `keylineTint` from it.
