import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch devices sorted by name.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WOLDevice.name, ascending: true)],
        animation: .default)
    private var devices: FetchedResults<WOLDevice>

    // If a default device exists, return it.
    // Otherwise, if one device exists, assume that is the default.
    private var deviceToWake: WOLDevice? {
        if let defaultDevice = devices.first(where: { $0.isDefault }) {
            return defaultDevice
        } else if devices.count == 1 {
            return devices.first
        } else {
            return nil
        }
    }

    var body: some View {
        VStack {
            if let device = deviceToWake {
                // Create a viewmodel for the device and pass it to the subview.
                DeviceWakeView(viewModel: DeviceViewModel(device: device, context: viewContext))
            } else {
                // No device found: show a message to the user.
                Text("Add a device to wake it")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

struct DeviceWakeView: View {
    @ObservedObject var viewModel: DeviceViewModel

    var body: some View {
        VStack {
            Button(action: {
                viewModel.sendWOLPacket()
            })
            {
                Text("Wake Device")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundColor(.white)
            }
            .foregroundColor(Color.green)
            .cornerRadius(8)
            .padding()

            Group {
                switch viewModel.sendStatus {
                case .idle:
                    EmptyView()
                case .sending:
                    Text("Sending...")
                        .foregroundColor(.blue)
                case .success:
                    Text("WOL packet sent successfully!")
                        .foregroundColor(.green)
                case .failure(let error):
                    Text("Failed to send WOL packet: \(error)")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Use the shared persistence container's view context
        let context = PersistenceController.shared.container.viewContext
        
        // Create a test device for preview purposes.
        let testDevice = WOLDevice(context: context)
        testDevice.name = "Test Device"
        testDevice.macAddress = "AA:BB:CC:DD:EE:FF"
        testDevice.broadcastAddress = Constants.defaultBroadcastAddress
        testDevice.port = 9
        testDevice.isDefault = true
        
        // Optionally, save the context to simulate a persisted device.
        do {
            try context.save()
        } catch {
            print("Error saving preview context: \(error)")
        }
        
        return ContentView()
            .environment(\.managedObjectContext, context)
    }
}
