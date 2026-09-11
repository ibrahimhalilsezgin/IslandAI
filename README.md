# IslandAI

IslandAI is an iOS 16.1+ application that leverages Live Activities (Dynamic Island & Lock Screen) via ActivityKit / WidgetKit.

## Architecture

- **IslandAI**: The main iOS app target.
- **IslandAIWidget**: The app extension target that provides WidgetKit and ActivityKit functionality.

## Requirements

- iOS 16.1+
- Xcode 14.1+ (for ActivityKit / Dynamic Island support)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for generating the Xcode project.

## Generating the Xcode Project

This project uses `XcodeGen` to manage the `.xcodeproj` file. Do not commit the `.xcodeproj` file.

1. Install XcodeGen (e.g., via Homebrew on macOS: `brew install xcodegen`)
2. Run XcodeGen in the project root:
   ```bash
   xcodegen generate
   ```
3. Open the generated `IslandAI.xcodeproj`.

## GitHub Actions Build

The repository is set up with GitHub Actions to build the project and produce an `.ipa` file artifact automatically on push/PR.

## Sideloading the `.ipa`

Since this app is distributed as an `.ipa` for sideloading, you can install it using Sideloadly, AltStore, or TrollStore.

### Using Sideloadly
1. Download and install [Sideloadly](https://sideloadly.io/).
2. Connect your iPhone to your computer via USB (or Wi-Fi).
3. Open Sideloadly and drag the built `.ipa` file into the IPA icon on the left.
4. Enter your Apple ID.
5. Click **Start**. Sideloadly will sign and install the app to your device.
6. On your iPhone, go to **Settings > General > VPN & Device Management**, tap your Apple ID, and choose **Trust**.

### Using AltStore
1. Download and install [AltStore](https://altstore.io/) on your computer and set it up on your device.
2. Transfer the `.ipa` file to your iPhone (e.g., via AirDrop or iCloud Drive).
3. Open AltStore on your device.
4. Go to the **My Apps** tab, tap the `+` icon in the top left, and select the `.ipa` file.
5. Log in with your Apple ID when prompted to install.

### Using TrollStore (For specific iOS versions)
1. If your device supports [TrollStore](https://github.com/opa334/TrollStore), install it.
2. Share the `.ipa` file to the TrollStore app, and it will permanently install without needing weekly resigns.
