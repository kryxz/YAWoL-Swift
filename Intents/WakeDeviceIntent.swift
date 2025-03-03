//
//  WakeDeviceIntent.swift
//  wol
//
//  Created by kryx on 2025/02/21.
//

import AppIntents
import SwiftUI
import CoreData

struct WakeDeviceIntent: AppIntent {
    static var title: LocalizedStringResource = "Wake Device"
    static var description = IntentDescription("Sends a WoL magic packet to a specified device.")
    
    @Parameter(
        title: "MAC Address",
        description: "The MAC address of the device to wake."
    )
    var macAddress: String
    
    @Parameter(
        title: "IP Address",
        description: "The IP address to send the magic packet to."
    )
    var ipAddress: String
    
    
    func perform() async throws -> some IntentResult {
        guard macAddress.isValidMacAddress else {
            throw NSError(
                domain: "WakeDeviceIntent",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid MAC address."]
            )
        }
        
        guard !ipAddress.isEmpty else {
            throw NSError(
                domain: "WakeDeviceIntent",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Invalid or missing IP address."]
            )
        }

        
        let context = PersistenceController.shared.container.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: "WOLDevice", in: context) else {
            throw NSError(
                domain: "WakeDeviceIntent",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Unable to find WOLDevice entity."]
            )
        }
        
        
        // Create a temporary WOLDevice without inserting it into the context.
        let wolDevice = WOLDevice(entity: entity, insertInto: nil)
        wolDevice.macAddress = macAddress
        wolDevice.ipAddress = ipAddress
        wolDevice.port = Int16(9)
        

        let result = WakeOnLan.send(to: wolDevice)
        
        switch result {
        case .success:
            return .result(value: "Magic packet sent successfully.")
        case .failure(let error):
            throw NSError(
                domain: "WakeDeviceIntent",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
        }
    }
}
