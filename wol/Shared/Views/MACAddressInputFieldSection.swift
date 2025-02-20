import SwiftUI

struct MACAddressInputFieldSection: View {
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    #if os(iOS)
                    TextField(placeholder, text: $text)
                        .autocapitalization(.allCharacters)
                        .frame(maxWidth: .infinity)
                    #elseif os(macOS)
                    TextField(placeholder, text: $text)
                        .frame(maxWidth: .infinity)
                    #endif
                    Button(action: {
                        #if os(iOS)
                        if let clipboardString = UIPasteboard.general.string,
                           clipboardString.isValidMacAddress {
                            text = clipboardString
                        }
                        #elseif os(macOS)
                        if let clipboardString = NSPasteboard.general.string(forType: .string),
                           clipboardString.isValidMacAddress {
                            text = clipboardString
                        }
                        #endif
                    }) {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .accessibilityLabel("Paste valid MAC address from clipboard")
                }
                // Display error message directly in the field if invalid.
                if !text.isEmpty && !text.isValidMacAddress {
                    Text("The MAC address isn't valid.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
        }
    }
}
