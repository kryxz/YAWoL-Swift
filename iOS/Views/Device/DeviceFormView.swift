import SwiftUI

struct DeviceFormView: View {
    @Binding var name: String
    @Binding var macAddress: String
    @Binding var ipAddress: String
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
                header: "IP ADDRESS",
                placeholder: "Enter IP Address",
                tip: "Optionally, enter your device's IP address for a more reliable connection.",
                text: $ipAddress
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
