import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch devices sorted with default devices first.
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "isDefault", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ],
        animation: .default
    ) private var devices: FetchedResults<WOLDevice>

    // Use the DevicesListViewModel to manage list-level actions.
    @StateObject private var listViewModel = DevicesListViewModel(context: PersistenceController.shared.container.viewContext)

    // Controls the display of the add-device sheet.
    @State private var showAddDeviceSheet = false

    // Returns the default device if available.
    private var displayedDefaultDevice: WOLDevice? {
        if devices.count > 1 {
            return devices.first(where: { $0.isDefault })
        } else {
            return devices.first
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func noDevicesView(width: CGFloat, height: CGFloat) -> some View {
        VStack {
            Spacer()
            Text("No device added")
                .font(.title)
            Spacer()
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private func singleDeviceView(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            if let device = devices.first {
                DefaultDeviceView(device: device, isSingleDevice: true)
                    .id(device.objectID)
                    .frame(height: height * 0.85)
            }
        }
        .frame(width: width, height: height)
    }

    
    private func multipleDevicesView(width: CGFloat, height: CGFloat) -> some View {
        // Extract the default device section into its own variable.
        let defaultDeviceContent: AnyView = {
            if let device = displayedDefaultDevice {
                return AnyView(
                    DefaultDeviceView(device: device)
                        .id(device.objectID)
                        .frame(height: height * 0.6)
                )
            } else {
                return AnyView(
                    VStack {
                        Spacer()
                        Text("Swipe right on a device to pin it")
                            .font(.title)
                        Spacer()
                    }
                    .frame(height: height * 0.6)
                )
            }
        }()

        return VStack(spacing: 0) {
            defaultDeviceContent
                .transition(.opacity)
                .animation(.easeInOut, value: displayedDefaultDevice)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(devices, id: \.objectID) { device in
                        DeviceRowView(
                            device: device
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(width: width, height: height)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {

            GeometryReader { geometry in
                if devices.isEmpty {
                    noDevicesView(width: geometry.size.width, height: geometry.size.height)
                } else if devices.count == 1 {
                    singleDeviceView(width: geometry.size.width, height: geometry.size.height)
                } else {
                    multipleDevicesView(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .sheet(isPresented: $showAddDeviceSheet) {
                AddDeviceView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddDeviceSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .accessibilityLabel("Add Device")
                }
            }

        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
