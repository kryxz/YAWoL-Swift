//
//  YAWoLApp-watchOS.swift
//  YAWoL Watch App
//
//  Created by kryx on 2025/02/18.
//

import SwiftUI


@main
struct WatchApp: App {

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
