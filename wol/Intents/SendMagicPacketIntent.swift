struct SendMagicPacketIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Magic Packet"
    static var description = IntentDescription("Sends a Wake-on-LAN magic packet to the default device.")

    // No parameters needed since we’re using the default device
    func perform() async throws -> some IntentResult {
        // Access your shared persistence controller (adjust if your implementation differs)
        let context = PersistenceController.shared.container.viewContext

        // Fetch the default device
        let request: NSFetchRequest<WOLDevice> = WOLDevice.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.fetchLimit = 1
        
        let devices = try context.fetch(request)
        guard let device = devices.first else {
            throw NSError(
                domain: "SendMagicPacketIntent",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No default device set."]
            )
        }
        
        // Validate MAC address using your utility extension
        let mac = device.macAddress ?? ""
        guard mac.isValidMacAddress else {
            throw NSError(
                domain: "SendMagicPacketIntent",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid MAC address."]
            )
        }
        
        // Determine broadcast address and port
        let broadcast = (device.broadcastAddress?.isEmpty ?? true) ? Constants.defaultBroadcastAddress : device.broadcastAddress!
        let port = (device.port == 0) ? Constants.defaultPort : device.port
        
        // Build the Wake-on-LAN device
        let wolDevice = WakeOnLan.Device(mac: mac, broadcastAddress: broadcast, port: port)
        let result = WakeOnLan.send(to: wolDevice)
        
        // Return the result based on the success or failure of sending the packet
        switch result {
        case .success:
            return .result(value: "Magic packet sent successfully.")
        case .failure(let error):
            throw NSError(
                domain: "SendMagicPacketIntent",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
        }
    }
}