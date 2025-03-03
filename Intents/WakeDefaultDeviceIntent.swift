//
//  WakeDefaultDeviceIntent.swift
//  wol
//
//  Created by kryx on 2025/02/21.
//
import AppIntents
import CoreData
import SwiftUI


// Expose the intent to Siri and Shortcuts with a title ("Wake Default Device")

struct WakeDefaultDeviceIntent: AppIntent {
    static var title: LocalizedStringResource = "Wake Default Device"
    static var description = IntentDescription("Sends a WoL magic packet to the default device.")
    
    func perform() async throws -> some IntentResult {
        
        let context = PersistenceController.shared.container.viewContext

        let request: NSFetchRequest<WOLDevice> = WOLDevice.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1
        
        let devices = try context.fetch(request)
        guard let device = devices.first else {
            throw NSError(
                domain: "WakeDefaultDeviceIntent",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No default device set."]
            )
        }
                
        
        let result = WakeOnLan.send(to: device)
        
        
        switch result {
        case .success:
            return .result(value: "Magic packet sent successfully.")
        case .failure(let error):
            throw NSError(
                domain: "WakeDefaultDeviceIntent",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
        }
    }
}
