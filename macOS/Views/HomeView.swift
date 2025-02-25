import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            DevicesListView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .frame(width: 300, height: 200)

            
        }
    }
}

#Preview {
    HomeView()
}
