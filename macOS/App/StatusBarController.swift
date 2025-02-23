
import SwiftUI
import AppKit
import CoreData

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    override init() {
        super.init()
        // Create the status item with a fixed (square) length.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = false
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            } else {
                button.title = "WOL"
            }
        
            
            // Set up the button's action to handle both left- and right-click.
            button.action = #selector(handleClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create the popover for left-click (using your SwiftUI ContentView).
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        let homeView = HomeView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        popover.contentViewController = NSHostingController(rootView: homeView)
    }
    
    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            // Right-click: show the custom menu.
            showCustomMenu()
        } else {
            // Left-click: toggle the popover.
            togglePopover(sender)
        }
    }
    
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func showCustomMenu() {
        let menu = NSMenu()
        
        let clearItem = NSMenuItem(title: "Clear Data", action: #selector(clearCoreData), keyEquivalent: "d")
        clearItem.target = self
        menu.addItem(clearItem)
        
        
        let quitItem = NSMenuItem(title: "Quit App", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc private func clearCoreData() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "WOLDevice")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        deleteRequest.resultType = .resultTypeObjectIDs
        do {
            if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
            try context.save()
            print("CoreData cleared!")
        } catch {
            print("Error clearing CoreData: \(error.localizedDescription)")
        }
    }
}
