import SwiftUI
import CoreData

struct DefaultDeviceView: View {
    var device: WOLDevice
    var isSingleDevice: Bool = false
    
    @StateObject private var viewModel: DeviceViewModel
    @State private var showEditSheet = false

    init(device: WOLDevice, isSingleDevice: Bool = false) {
        self.device = device
        self.isSingleDevice = isSingleDevice
        _viewModel = StateObject(wrappedValue: DeviceViewModel(
            device: device,
            context: device.managedObjectContext ?? PersistenceController.shared.container.viewContext
        ))
    }

    private var wakeButtonImage: Image {
        switch viewModel.sendStatus {
        case .idle, .sending:
            return Image(systemName: "power.circle.fill")
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        case .failure:
            return Image(systemName: "xmark.circle.fill")
        }
    }
    
    private var wakeButtonColor: Color {
        switch viewModel.sendStatus {
        case .idle:
            return Color.green
        case .sending:
            return Color.yellow
        case .success:
            return Color.green
        case .failure:
            return Color.red
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with toggle icon and title.
                VStack(spacing: 12) {
                    ToggleComputerIconView()
                }
                .padding(.top, 10)
                
                // Device information.
                VStack(spacing: 8) {
                    Button(action: { showEditSheet = true }) {
                        Text(viewModel.name.isEmpty ? Constants.defaultDeviceName : viewModel.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    // Present the AddDeviceView as a sheet.
                    .sheet(isPresented: $showEditSheet) {
                        AddDeviceView(device: device)
                            .environment(\.managedObjectContext, device.managedObjectContext ?? PersistenceController.shared.container.viewContext)
                    }
                    
                    Text(viewModel.macAddress.isEmpty ? "No MAC Address" : viewModel.macAddress)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    viewModel.sendWOLPacket()
                }) {
                    wakeButtonImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isSingleDevice ? 250 : 200, height: isSingleDevice ? 250 : 200)
                        .foregroundColor(wakeButtonColor)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 10, y: 5)
                        .animation(.easeInOut, value: viewModel.sendStatus)
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
        }
    }
}

struct DefaultDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let device = WOLDevice(context: context)
        device.name = Constants.defaultDeviceName
        device.macAddress = Constants.defaultMacAddress
        return Group {
            DefaultDeviceView(device: device, isSingleDevice: true)
                .environment(\.managedObjectContext, context)
            DefaultDeviceView(device: device, isSingleDevice: false)
                .environment(\.managedObjectContext, context)
        }
    }
}
