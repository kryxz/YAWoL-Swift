# YAWoL (Yet Another Wake-on-LAN)

The app I was using stopped showing up in Shortcuts and Siri, so I built YAWoL as a an alternative. This app sends magic packets to gently wake up your devices. Works and syncs between macOS, iOS, and watchOS.

## Features

- **Wake Devices:** Send magic packets to wake devices.
- **Cross-Platform:** Runs on macOS, iOS, & watchOS.
- **CloudKit:** Sync devices via iCloud.
- **Shortcuts:** Automate with Apple Shortcuts.

## Structure

This is one of my attempts tackling the KISS (Keep It Simple, Stupid) and DRY (Don't Repeat Yourself) principles. The Apple ecosystem certainly helps with both.

- **Shared Module:**
All core functionality—configurations, data models, persistence, utilities, and shared view models—into one place.

- **Platform-Specific Modules:**
  - Platform-specific app setup
  - Custom UI implementations
  - Platform-specific features and optimizations

This modular approach not only simplifies the codebase but also makes maintenance and platform-specific enhancements a breeze.

## Screenshots

### macOS

![macOS Screenshot](https://i.imgur.com/OxnTGUi.png)

### iOS

![iOS Screenshot](https://i.imgur.com/t7ab3xr.png)

### watchOS

![watchOS Screenshot](https://i.imgur.com/ILbH9DA.png)

### Shortcuts

![Shortcuts Screenshot](https://i.imgur.com/BLCeQ7M.png)
