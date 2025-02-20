import SwiftUI

struct DeviceRowView: View {
    @StateObject private var viewModel: DeviceViewModel
    @State private var dragOffset: CGFloat = 0  // For tracking drag gesture (both directions)
    @State private var isVisible: Bool = true   // For fade-out animation
    @State private var showAdvancedSettings: Bool = false
    
    // Focus state for text fields.
    enum Field: Hashable {
        case name, mac, broadcast, port
    }
    @FocusState private var focusedField: Field?
    
    private let autoEdit: Bool
    private let autoFocus: Bool

    init(device: WOLDevice, autoEdit: Bool = false, autoFocus: Bool = false) {
        // Create the view model from the device.
        _viewModel = StateObject(wrappedValue: DeviceViewModel(device: device, context: device.managedObjectContext ?? PersistenceController.shared.container.viewContext))
        self.autoEdit = autoEdit
        self.autoFocus = autoFocus
    }

    var body: some View {
        ZStack {
            // Background overlay with icons that become visible on drag.
            HStack {
                // Left side: Pin icon appears only when swiping right.
                Image(systemName: viewModel.isDefault ? "pin.fill" : "pin")
                    .font(.title)
                    .foregroundColor(.yellow)
                    .padding(.leading, 16)
                    .opacity(dragOffset > 0 ? min(Double(dragOffset) / 50.0, 1) : 0)
                Spacer()
                // Right side: Trash icon appears only when swiping left.
                Image(systemName: "trash")
                    .font(.title)
                    .foregroundColor(.red)
                    .padding(.trailing, 16)
                    .opacity(dragOffset < 0 ? min(Double(-dragOffset) / 50.0, 1) : 0)
            }
            
            // Main content.
            VStack(spacing: 0) {
                if viewModel.isEditing {
                    HStack(spacing: 8) {
                        TextField("Name", text: $viewModel.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .name)
                            .frame(minWidth: 80, maxWidth: 120)
                        TextField("MAC Address", text: $viewModel.macAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minWidth: 100, maxWidth: 150)
                        HStack(spacing: 4) {
                            Button(action: viewModel.saveChanges) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Button(action: viewModel.cancelEditing) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Button(action: {
                                withAnimation { showAdvancedSettings.toggle() }
                            }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    
                    if showAdvancedSettings {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Broadcast Address", text: $viewModel.broadcastAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: .broadcast)
                            TextField("Port", value: $viewModel.port, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: .port)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewModel.name.isEmpty ? Constants.defaultDeviceName : viewModel.name)
                                .lineLimit(1)
                            Text(viewModel.macAddress.isEmpty ? "No MAC" : viewModel.macAddress)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: viewModel.sendWOLPacket) {
                            Text("Wake")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                }
                Divider()
            }
            .padding(.vertical, 2)
            .offset(x: dragOffset)
            .opacity(isVisible ? 1 : 0)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { _ in
                        let deletionThreshold: CGFloat = -50
                        let pinThreshold: CGFloat = 50
                        if dragOffset < deletionThreshold {
                            // Left swipe: delete.
                            withAnimation {
                                dragOffset = -200
                                isVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.deleteDevice()
                            }
                        } else if dragOffset > pinThreshold {
                            // Right swipe: toggle default.
                            viewModel.toggleDefault()
                            withAnimation { dragOffset = 0 }
                        } else {
                            withAnimation { dragOffset = 0 }
                        }
                    }
            )
        }
        .onAppear {
            // If this row was created as a new device, trigger editing after the view is installed.
            if autoEdit && !viewModel.isEditing {
                viewModel.startEditing()
                if autoFocus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.focusedField = .name
                    }
                }
            }
        }
        // Tapping the row toggles editing mode.
        .onTapGesture {
            if !viewModel.isEditing {
                viewModel.startEditing()
            }
        }
    }
}

struct DeviceRowView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let device = WOLDevice(context: context)
        device.name = Constants.defaultDeviceName
        device.macAddress = Constants.defaultMacAddress
        device.broadcastAddress = Constants.defaultBroadcastAddress
        device.port = Constants.defaultPort
        // For preview, you might want to test both states:
        device.isDefault = false
        return DeviceRowView(device: device, autoEdit: false, autoFocus: false)
            .environment(\.managedObjectContext, context)
            .previewLayout(.sizeThatFits)
    }
}
