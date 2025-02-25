//
//  YAWoLApp-macos.swift
//  YAWoL macOS
//
//  Created by kryx on 2025/02/18.
//


import SwiftUI

@main
struct macOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
