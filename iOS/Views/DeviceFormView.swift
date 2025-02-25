import SwiftUI

struct DeviceFormView: View {
    @Binding var name: String
    @Binding var macAddress: String
    @Binding var broadcastAddress: String
    @Binding var port: String

    var deviceNameSuggestion: String {
        let suggestions = [
            "Captain Wake",
            "Sir Wakes-a-Lot",
            "The Great Machine",
            "My Shiny Device",
            "Ze Device",
            "Wakey McWakeface",
            "The Slumberjack",
            "The Sleep Disruptor 5000"
        ]
        return suggestions.randomElement() ?? "Unnamed Device"
    }
    
    var body: some View {
        Form {
            InputFieldSection(
                header: "DEVICE NAME GOES HERE",
                placeholder: "Enter device name",
                tip: "How about \(deviceNameSuggestion)?",
                text: $name
            )
            
            MACAddressInputFieldSection(
                header: "MAC ADDRESS",
                placeholder: "Enter MAC Address",
                tip: "Enter the MAC address (e.g. 00:11:22:33:44:55).",
                text: $macAddress
            )
            
            InputFieldSection(
                header: "BROADCAST ADDRESS",
                placeholder: "Enter Broadcast Address",
                tip: "Enter your network's broadcast address. For most, '255.255.255.255' works, but you may need your subnet's specific broadcast (e.g., 192.168.1.255).",
                text: $broadcastAddress
            )
            
            InputFieldSection(
                header: "PORT",
                placeholder: "Enter Port",
                tip: "Port doesn't affect the WoL functionality, but 9 is generally the default port.",
                text: $port
            )
        }
        .listStyle(InsetGroupedListStyle())
    }
}


struct InputFieldSection: View {
    let header: String
    let placeholder: String
    let tip: String
    @Binding var text: String

    var body: some View {
        Section(
            header: Text(header),
            footer: Text(tip)
                .font(.footnote)
                .foregroundColor(.secondary)
        ) {
            TextField(placeholder, text: $text)
                .frame(maxWidth: .infinity)
        }
    }
}
