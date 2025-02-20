import SwiftUI
import CoreData

struct AddDeviceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // Optional device for editing. If nil, we're adding a new device.
    var device: WOLDevice?
    
    // State properties are initialized from the device if available.
    @State private var name: String
    @State private var macAddress: String
    @State private var broadcastAddress: String
    @State private var port: String

    // Custom initializer that pre-populates the fields when editing.
    init(device: WOLDevice? = nil) {
        self.device = device
        _name = State(initialValue: device?.name ?? "")
        _macAddress = State(initialValue: device?.macAddress ?? "")
        _broadcastAddress = State(initialValue: device?.broadcastAddress ?? Constants.defaultBroadcastAddress)
        _port = State(initialValue: device != nil ? String(device!.port) : String(Constants.defaultPort))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with icon and title.
                VStack(spacing: 16) {
                    ToggleComputerIconView()
                        .padding(.top, 10)
                    Text(device == nil ? "Add Device" : "Edit Device")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Extracted form view.
                DeviceFormView(
                    name: $name,
                    macAddress: $macAddress,
                    broadcastAddress: $broadcastAddress,
                    port: $port
                )
                
                // Save/Add Device Button
                Button(action: saveDevice) {
                    Text(device == nil ? "Add Device" : "Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding([.leading, .trailing, .bottom])
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    /// Saves the device: creates a new one if none exists or updates the existing device.
    private func saveDevice() {
        if let device = device {
            // Update existing device.
            device.name = name
            device.macAddress = macAddress
            device.broadcastAddress = broadcastAddress
            if let portNumber = Int16(port) {
                device.port = portNumber
            } else {
                device.port = 9
            }
        } else {
            // Create a new device.
            let newDevice = WOLDevice(context: viewContext)
            newDevice.name = name
            newDevice.macAddress = macAddress
            newDevice.broadcastAddress = broadcastAddress
            if let portNumber = Int16(port) {
                newDevice.port = portNumber
            } else {
                newDevice.port = 9
            }
            newDevice.isDefault = false
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving device: \(error)")
        }
    }
}

struct AddDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        
        // Preview in Add mode.
        Group {
                        
            // Preview in Edit mode.
            let device = WOLDevice(context: context)
            device.name = Constants.defaultDeviceName
            device.macAddress = Constants.defaultMacAddress
            device.broadcastAddress = Constants.defaultBroadcastAddress
            device.port = Constants.defaultPort
            return AddDeviceView(device: device)
                .environment(\.managedObjectContext, context)
        }
    }
}
