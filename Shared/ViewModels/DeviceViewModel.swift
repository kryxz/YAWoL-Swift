import SwiftUI
import CoreData

class DeviceViewModel: ObservableObject {
    @Published var name: String
    @Published var macAddress: String
    @Published var broadcastAddress: String
    @Published var port: Int16
    @Published var isEditing: Bool = false

    private var device: WOLDevice
    private var context: NSManagedObjectContext

    init(device: WOLDevice, context: NSManagedObjectContext) {
        self.device = device
        self.context = context
        // Instead of copying the values, you might observe changes on `device`.
        self.name = device.name ?? ""
        self.macAddress = device.macAddress ?? ""
        self.broadcastAddress = device.broadcastAddress ?? Constants.defaultBroadcastAddress
        self.port = device.port == 0 ? Constants.defaultPort : device.port
        
        // Subscribe to changes on the device if needed.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(notification:)),
            name: .NSManagedObjectContextDidSave,
            object: context
        )
    }

    @objc private func contextDidSave(notification: Notification) {
        // Refresh the device and update the published properties.
        context.refresh(device, mergeChanges: true)
        DispatchQueue.main.async {
            self.name = self.device.name ?? ""
            self.macAddress = self.device.macAddress ?? ""
            self.broadcastAddress = self.device.broadcastAddress ?? Constants.defaultBroadcastAddress
            self.port = self.device.port == 0 ? Constants.defaultPort : self.device.port
            self.objectWillChange.send()
        }
    }
    
    
    enum SendStatus: Equatable {
        case idle, sending, success, failure(String)
    }
    
    
    @Published var sendStatus: SendStatus = .idle
    
    
    var deviceName: String {
        device.name ?? "Device"
    }
    
    // Expose the underlying device for editing.
    var deviceForEditing: WOLDevice {
        return device
    }
    
    var isDefault: Bool {
        return device.isDefault
    }
    
    func startEditing() {
        isEditing = true
    }
    
    func saveChanges() {
        if macAddress.isValidMacAddress {
            device.name = name
            device.macAddress = macAddress
            device.broadcastAddress = broadcastAddress
            device.port = port
            do {
                try context.save()
                isEditing = false
            } catch {
                print("Error saving changes: \(error.localizedDescription)")
            }
        } else {
            deleteDevice()
        }
    }
    
    func cancelEditing() {
        if !macAddress.isValidMacAddress {
            deleteDevice()
        } else {
            name = device.name ?? ""
            macAddress = device.macAddress ?? ""
            broadcastAddress = device.broadcastAddress ?? Constants.defaultBroadcastAddress
            port = device.port == 0 ? Constants.defaultPort : device.port
            isEditing = false
        }
    }
    
    func deleteDevice() {
        context.delete(device)
        do {
            try context.save()
        } catch {
            print("Error deleting device: \(error.localizedDescription)")
        }
    }
    
    func sendWOLPacket() {
        
        if !macAddress.isValidMacAddress {
            DispatchQueue.main.async {
                self.sendStatus = .failure("Invalid MAC address")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.sendStatus = .idle
                }
            }
            return
        }
        
        
        DispatchQueue.main.async {
            self.sendStatus = .sending
        }
        
        let broadcast = broadcastAddress.isEmpty ? Constants.defaultBroadcastAddress : broadcastAddress
        let wolDevice = WakeOnLan.Device(mac: macAddress, broadcastAddress: broadcast, port: port)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = WakeOnLan.send(to: wolDevice)
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.sendStatus = .success
                case .failure(let error):
                    self.sendStatus = .failure(error.localizedDescription)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.sendStatus = .idle
                }
            }
        }
    }
    
    
    func toggleDefault() {
        let fetchRequest: NSFetchRequest<WOLDevice> = WOLDevice.fetchRequest()
        do {
            let devices = try context.fetch(fetchRequest)
            if device.isDefault {
                device.isDefault = false
            } else {
                for dev in devices {
                    dev.isDefault = false
                }
                device.isDefault = true
            }
            try context.save()
        } catch {
            print("Error toggling default: \(error.localizedDescription)")
        }
    }
}
