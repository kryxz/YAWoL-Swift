import SwiftUI
import CoreData

struct ToggleComputerIconView: View {
    @State private var isDesktop = true

    var body: some View {
        ZStack {
            Image(systemName: "desktopcomputer")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            Text(isDesktop ? ":)" : ":/")
                .font(.largeTitle)
                .foregroundColor(.primary)
                .padding(4)
                .rotationEffect(Angle.degrees(90))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .offset(y: -10)
        }
        .onTapGesture {
            withAnimation {
                isDesktop.toggle()
            }
        }
    }
}
