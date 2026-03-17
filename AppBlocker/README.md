# App Blocker — iOS

A native iOS app (iPhone + iPad) that lets you block distracting apps using Apple's **Screen Time API**.

## Features

| Feature | Description |
|---|---|
| App & Category Selection | Pick any installed app or category via Apple's native `FamilyActivityPicker` |
| Instant Blocking | Toggle blocking on/off with one tap |
| Daily Schedule | Automatically block apps between two times every day |
| iPad Support | Fully adaptive SwiftUI layout |

## Architecture

```
AppBlocker/
├── AppBlockerApp.swift      # @main entry, requests Screen Time auth on launch
├── BlockingManager.swift    # ObservableObject wrapping FamilyControls + ManagedSettings
├── ContentView.swift        # Tab bar: Home / Schedule / Settings
├── AppSelectionView.swift   # FamilyActivityPicker wrapper
├── ScheduleView.swift       # Daily schedule picker (DeviceActivity)
├── Info.plist               # NSFamilyControlsUsageDescription required
└── AppBlocker.entitlements  # com.apple.developer.family-controls
```

## Requirements

- **Xcode 15+**
- **iOS 16+** deployment target
- An **Apple Developer account** (free tier works for device testing)
- The `com.apple.developer.family-controls` entitlement
  - For **development/testing**: enabled automatically with a paid developer account
  - For **App Store distribution**: requires [manual approval from Apple](https://developer.apple.com/contact/request/family-controls-distribution)

## Getting Started

1. Open `AppBlocker.xcodeproj` in Xcode
2. Change the **Bundle Identifier** to your own (e.g. `com.yourname.appblocker`)
3. Set your **Development Team** under Signing & Capabilities
4. Run on a **real device** (Screen Time API does not work in Simulator)

## Frameworks Used

| Framework | Purpose |
|---|---|
| `FamilyControls` | Request Screen Time authorization, present app picker |
| `ManagedSettings` | Apply app shields (blocking) |
| `DeviceActivity` | Schedule blocking periods |
| `SwiftUI` | UI |
