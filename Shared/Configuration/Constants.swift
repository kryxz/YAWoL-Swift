
import Foundation

public struct Constants {
    
    // placeholder values
    public static let defaultBroadcastAddress: String = "255.255.255.255"
    public static let defaultMacAddress: String = "00:11:22:33:44:55"
    public static let defaultDeviceName: String = "Unnamed Device"
    public static let defaultIpAddress: String = "192.168.1.10"
    public static let defaultPort: Int16 = 9
    
    /// Core Data / CloudKit record type for a WOL device.
    static let deviceRecordType: String = "WOLDevice"
    static let defaultContainer: String = "iCloud.com.kryx.wol"
}
