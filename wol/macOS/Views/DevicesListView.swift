import SwiftUI
import CoreData

struct DevicesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "isDefault", ascending: false), // default devices first
            NSSortDescriptor(key: "name", ascending: true)
        ],
        animation: .default)
    
    private var devices: FetchedResults<WOLDevice>
    
    @StateObject private var viewModel = DevicesListViewModel(context: PersistenceController.shared.container.viewContext)
    
    var body: some View {
        VStack(spacing: 4) {
            ScrollViewReader { proxy in
                List {
                    ForEach(devices, id: \.objectID) { device in
                        // Pass autoEdit/autoFocus if this device is the new one.
                        DeviceRowView(
                            device: device,
                            autoEdit: device.objectID == viewModel.newDeviceID,
                            autoFocus: device.objectID == viewModel.newDeviceID
                        )
                        .id(device.objectID)
                        .environment(\.managedObjectContext, viewContext)
                    }
                    .onDelete { offsets in
                        viewModel.deleteDevices(offsets: offsets, devices: devices)
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: viewModel.newDeviceID) { _, newValue in
                    if let newValue = newValue {
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .top)
                        }
                    }
                }
            }
            
            // Bottom bar with Quit and Add buttons.
            HStack {
                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "xmark.octagon")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Button(action: {
                    viewModel.addNewDevice()
                }) {
                    Image(systemName: "plus.square")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
        .padding(.vertical, 4)
    }
}

struct DevicesListView_Previews: PreviewProvider {
    static var previews: some View {
        DevicesListView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
