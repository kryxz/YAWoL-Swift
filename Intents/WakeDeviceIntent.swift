//
//  WakeDeviceIntent.swift
//  wol
//
//  Created by kryx on 2025/02/21.
//

import AppIntents
import SwiftUI

struct WakeDeviceIntent: AppIntent {
    static var title: LocalizedStringResource = "Wake Device"
    static var description = IntentDescription("Sends a WoL magic packet to a specified device.")
    
    @Parameter(
        title: "MAC Address",
        description: "The MAC address of the device to wake."
    )
    var macAddress: String
    
    @Parameter(
        title: "Broadcast Address",
        description: "The broadcast address to send the magic packet to.",
        default: "255.255.255.255"
    )
    var broadcastAddress: String
    
    
    func perform() async throws -> some IntentResult {
        guard macAddress.isValidMacAddress else {
            throw NSError(
                domain: "WakeDeviceIntent",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid MAC address."]
            )
        }
        
        // Use provided broadcast address and port, or default if needed.
        let finalBroadcast = broadcastAddress.isEmpty ? Constants.defaultBroadcastAddress : broadcastAddress
        let finalPort = Int16(9)
        
        let wolDevice = WakeOnLan.Device(mac: macAddress, broadcastAddress: finalBroadcast, port: finalPort)
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
