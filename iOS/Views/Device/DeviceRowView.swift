import SwiftUI

struct DeviceRowView: View {
    @StateObject private var viewModel: DeviceViewModel
    @State private var dragOffset: CGFloat = 0  // For tracking swipe gesture.
    @State private var isVisible: Bool = true   // For fade-out animation.
    @State private var showEditSheet: Bool = false

    init(device: WOLDevice) {
        _viewModel = StateObject(wrappedValue: DeviceViewModel(
            device: device,
            context: device.managedObjectContext ?? PersistenceController.shared.container.viewContext
        ))
    }
    
    // Computed properties to choose button image and color based on sendStatus.
    private var wakeButtonImage: Image {
        switch viewModel.sendStatus {
        case .idle, .sending:
            return Image(systemName: "power")
        case .success:
            return Image(systemName: "checkmark.circle")
        case .failure:
            return Image(systemName: "xmark.circle")
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
        ZStack {
            // Background overlay for swipe actions.
            HStack {
                Image(systemName: viewModel.isDefault ? "pin.fill" : "pin")
                    .font(.title)
                    .foregroundColor(.yellow)
                    .padding(.leading, 16)
                    .opacity(dragOffset > 0 ? min(Double(dragOffset) / 50.0, 1) : 0)
                Spacer()
                Image(systemName: "trash")
                    .font(.title)
                    .foregroundColor(.red)
                    .padding(.trailing, 16)
                    .opacity(dragOffset < 0 ? min(Double(-dragOffset) / 50.0, 1) : 0)
            }
            
            // Main content.
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.name.isEmpty ? Constants.defaultDeviceName : viewModel.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(viewModel.macAddress.isEmpty ? "No MAC" : viewModel.macAddress)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    viewModel.sendWOLPacket()
                }) {
                    wakeButtonImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(wakeButtonColor)
                        .animation(.easeInOut, value: viewModel.sendStatus)
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
            .contentShape(Rectangle())
            .offset(x: dragOffset)
            .opacity(isVisible ? 1 : 0)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only handle horizontal drags.
                        if abs(value.translation.width) > abs(value.translation.height) {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            let deletionThreshold: CGFloat = -25
                            let pinThreshold: CGFloat = 25
                            if dragOffset < deletionThreshold {
                                withAnimation {
                                    dragOffset = -200
                                    isVisible = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.deleteDevice()
                                }
                            } else if dragOffset > pinThreshold {
                                viewModel.toggleDefault()
                                withAnimation { dragOffset = 0 }
                            } else {
                                withAnimation { dragOffset = 0 }
                            }
                        } else {
                            withAnimation { dragOffset = 0 }
                        }
                    }
            )
        }
        .onTapGesture {
            showEditSheet = true
        }
        .sheet(isPresented: $showEditSheet) {
            AddDeviceView(device: viewModel.deviceForEditing)
                .environment(
                    \.managedObjectContext,
                    viewModel.deviceForEditing.managedObjectContext ?? PersistenceController.shared.container.viewContext
                )
        }
    }
}

struct DeviceRowView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let device = WOLDevice(context: context)
        device.name = Constants.defaultDeviceName
        device.macAddress = Constants.defaultMacAddress
        device.ipAddress = Constants.defaultIpAddress
        device.port = Constants.defaultPort
        device.isDefault = false
        return DeviceRowView(device: device)
            .environment(\.managedObjectContext, context)
            .previewLayout(.sizeThatFits)
    }
}
