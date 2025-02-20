


import SwiftUI

struct LabeledTextFieldWithTooltip: View {
    var placeholder: String
    @Binding var text: String
    var tooltip: String
    var keyboardType: UIKeyboardType = .default

    @State private var showTooltip: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                Button(action: {
                    withAnimation {
                        showTooltip.toggle()
                    }
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            if showTooltip {
                Text(tooltip)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
    }
}
