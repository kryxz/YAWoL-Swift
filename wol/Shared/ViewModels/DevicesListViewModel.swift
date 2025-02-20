import SwiftUI
import CoreData

class DevicesListViewModel: ObservableObject {
    /// This is used to mark a newly created device so that its row starts in editing mode.
    @Published var newDeviceID: NSManagedObjectID? = nil
    
    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    /// Adds a new device to Core Data. If there’s no device in the store, mark this one as default.
    func addNewDevice() {
        let newDevice = WOLDevice(context: viewContext)
        newDevice.name = ""
        newDevice.macAddress = ""
        
        // Check if there are any devices already.
        let fetchRequest: NSFetchRequest<WOLDevice> = WOLDevice.fetchRequest()
        if let count = try? viewContext.count(for: fetchRequest), count == 0 {
            newDevice.isDefault = true
        } else {
            newDevice.isDefault = false
        }
        
        #if os(macOS)
        let pasteboardString = NSPasteboard.general.string(forType: .string) ?? ""
        newDevice.macAddress = pasteboardString.isValidMacAddress ? pasteboardString : ""
        #endif
       
        do {
            try viewContext.save()
            newDeviceID = newDevice.objectID
        } catch {
            print("Error saving new device: \(error.localizedDescription)")
        }
    }
    
    /// Deletes devices at the given offsets.
    func deleteDevices(offsets: IndexSet, devices: FetchedResults<WOLDevice>) {
        offsets.map { devices[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting device: \(error.localizedDescription)")
        }
    }
}
