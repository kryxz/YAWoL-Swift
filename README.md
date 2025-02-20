# Wake-On-Lan App

A Wake-On-Lan application built with Swift for macOS, iOS, and watchOS. This app allows you to send wake signals to your devices over the network and manage them with an intuitive interface.


## Features

- **Wake Devices:** Send wake signals to network-connected devices.
- **Cross-Platform:** Works seamlessly on macOS, iOS, and watchOS.
- **CloudKit Integration:** Sync your device configurations using iCloud.
- **Shortcuts Integration:** Integrate with Apple Shortcuts for automation.

## Architecture

The project is designed with modularity and code reuse in mind:

- **Shared Module:**  
In the Shared folder, you’ll find all the core stuff—configurations, data models, persistence, utilities, and view models. This code is shared across all platforms to keep things consistent and avoid repeating yourself.

- **Platform-Specific:**  
  - **macOS:** Check out the `macOS` folder (inside the main wol directory) for macOS-specific UI bits like the AppDelegate, StatusBarController, and custom views.
  - **iOS:** The `WoL-iOS` folder holds code and views tailored for a mobile experience.
  - **watchOS:** The `WoL Watch App` folder has lightweight interfaces designed just for watchOS.

This architecture promotes a clear separation of concerns and streamlines future enhancements and maintenance.



## Screenshots

### macOS
![macOS Screenshot](https://i.imgur.com/OxnTGUi.png)

### iOS
![iOS Screenshot](https://i.imgur.com/t7ab3xr.png)

### watchOS
![watchOS Screenshot](https://i.imgur.com/ILbH9DA.png)

