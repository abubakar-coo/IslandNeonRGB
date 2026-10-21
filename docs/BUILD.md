# Building and testing IslandNeonRGB

## Requirements

| Item | Version |
|---|---|
| macOS with Xcode | Xcode 16.0 or newer (project uses file-system-synchronized groups, `objectVersion = 77`) |
| iOS deployment target | 17.0 |
| Device | Any iPhone with a Dynamic Island (14 Pro and later). The simulator can run the app and the Live Activity, but calibration against the real cutout only makes sense on hardware. |
| Apple Developer account | Free or paid; needed to run on a device |

## 1. Open the project

```bash
open IslandNeonRGB.xcodeproj
```

If Xcode refuses to open the hand-written project for any reason, regenerate it:

```bash
brew install xcodegen
xcodegen generate
open IslandNeonRGB.xcodeproj
```

## 2. Signing

Both targets use automatic signing with placeholder bundle identifiers:

| Target | Bundle ID |
|---|---|
| IslandNeonRGB | `com.example.IslandNeonRGB` |
| IslandNeonWidgetExtension | `com.example.IslandNeonRGB.IslandNeonWidget` |

In **Signing & Capabilities**, select your Team for *both* targets. Change the prefix
`com.example` to your own reverse-DNS prefix on both; the extension's ID must stay a child
of the app's ID. No capabilities need to be added: local Live Activities need only the
`NSSupportsLiveActivities` Info.plist key, which is already set.

## 3. Build and run

Select the `IslandNeonRGB` scheme and a device, then **Run** (⌘R). Xcode builds the widget
extension first (the app target depends on it) and embeds it in the app.

Command line equivalent:

```bash
xcodebuild -project IslandNeonRGB.xcodeproj -scheme IslandNeonRGB \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

For the simulator:

```bash
xcodebuild -project IslandNeonRGB.xcodeproj -scheme IslandNeonRGB \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

## 4. Testing checklist

1. **Neon tab.** The mockup animates. Change the colour mode; the stroke and glow update.
   Speed, brightness and glow sliders respond live.
2. **Align to the real Dynamic Island.** Tap the button. The status bar hides and the
   outline appears around the hardware cutout. Tap **Calibrate** and adjust width, height,
   top inset and offset until the stroke hugs the cutout. Values persist.
3. **Live Activity tab.** Tap **Start Live Activity**. Swipe to the Home Screen: the
   island shows a gradient dot and "RGB". Long-press the island to expand it and observe
   the coloured keyline. Return to the app; the "Updates sent" counter climbs every
   *N* seconds and the keyline colour steps through the palette. Tap **Stop**.
4. **Settings tab.** The phone mockup at the top mirrors every change. "Detected" shows
   the device preset matched from the screen size.
5. **Reduce Motion.** Enable it in iOS Settings → Accessibility; the stroke freezes.
6. **Previews.** `IslandNeonLiveActivity.swift` has `#Preview` blocks for the expanded,
   compact, minimal and Lock Screen presentations.

## 5. Expected warnings

* The app icon set contains no images (a placeholder); Xcode warns but builds. Add
  1024×1024 PNGs before archiving for TestFlight.
* Swift 6 strict concurrency is off (`SWIFT_VERSION = 5.0`). Turning it on will surface
  `Sendable` diagnostics around `Activity` streams that are harmless in Swift 5 mode.

## 6. Reporting build errors

This project was written on a Windows machine without Xcode and has not been compiled.
If the first build fails, the most likely spots are:

* API availability typos in `IslandNeonLiveActivity.swift` (`#Preview … as:using:contentStates:`),
* `@Bindable` shadowing inside `body` in the settings views,
* implicit `Double`/`CGFloat` conversions in `NeonIslandFrame`.

Paste the error text and file/line into an issue or back to the assistant; each should be
a one-line fix.
