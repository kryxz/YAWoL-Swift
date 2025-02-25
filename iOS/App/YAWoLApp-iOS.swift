//
//  YAWoLApp-iOS.swift
//  YAWoL iOS
//
//  Created by kryx on 2025/02/18.
//

import SwiftUI

@main
struct iOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
