//
//  SendMagicPacketIntent.swift
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
        
        let mac = device.macAddress ?? ""
        guard mac.isValidMacAddress else {
            throw NSError(
                domain: "WakeDefaultDeviceIntent",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid MAC address."]
            )
        }
        
        let broadcast = (device.broadcastAddress?.isEmpty ?? true) ? Constants.defaultBroadcastAddress : device.broadcastAddress!
        let port = (device.port == 0) ? Constants.defaultPort : device.port
        
        let wolDevice = WakeOnLan.Device(mac: mac, broadcastAddress: broadcast, port: port)
        let result = WakeOnLan.send(to: wolDevice)
        
        
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
