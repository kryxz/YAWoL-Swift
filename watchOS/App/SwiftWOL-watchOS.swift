//
//  WoLApp.swift
//  WoL Watch App
//
//  Created by kryx on 2025/02/18.
//

import SwiftUI


@main
struct WoL_WatchApp: App {
    // In this example, we’re using the shared persistence controller.
    // In a real watchOS app you might want to create a dedicated container.
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
