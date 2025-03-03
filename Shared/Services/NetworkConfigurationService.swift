import Foundation
import Network

public class NetworkConfigurationService {
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")

    public init() {
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }
    
    public func isConnectedToWifi(completion: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { path in
            completion(path.status == .satisfied && path.usesInterfaceType(.wifi))
        }
    }

    public func validateMacAddress(_ macAddress: String) -> Result<Void, AppError> {
        guard macAddress.isValidMacAddress else {
            return .failure(.invalidMacAddress(macAddress))
        }
        return .success(())
    }

    public func getSubnetMask(for interfaceName: String = "en0") -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == interfaceName, let netmaskPtr = interface.ifa_netmask {
                    var addr = netmaskPtr.pointee
                    var netmaskAddr = withUnsafePointer(to: &addr) {
                        $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                            $0.pointee.sin_addr
                        }
                    }
                    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    inet_ntop(AF_INET, &netmaskAddr, &buffer, socklen_t(INET_ADDRSTRLEN))
                    return String(cString: buffer)
                }
            }
        }
        return nil
    }
    
    public func getCurrentWiFiIPAddress(for interfaceName: String = "en0") -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == interfaceName {
                    var addr = interface.ifa_addr.pointee
                    var ipAddr = withUnsafePointer(to: &addr) {
                        $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                            $0.pointee.sin_addr
                        }
                    }
                    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    inet_ntop(AF_INET, &ipAddr, &buffer, socklen_t(INET_ADDRSTRLEN))
                    return String(cString: buffer)
                }
            }
        }
        return nil
    }
    
    public func getBroadcastAddress(forIP ipAddress: String, withSubnetMask subnetMask: String) -> String? {
        let ipComponents = ipAddress.split(separator: ".")
        guard ipComponents.count == 4,
              let octet1 = UInt8(ipComponents[0]),
              let octet2 = UInt8(ipComponents[1]),
              let octet3 = UInt8(ipComponents[2]),
              let octet4 = UInt8(ipComponents[3]) else {
            return nil
        }
        
        let maskComponents = subnetMask.split(separator: ".")
        guard maskComponents.count == 4,
              let maskOctet1 = UInt8(maskComponents[0]),
              let maskOctet2 = UInt8(maskComponents[1]),
              let maskOctet3 = UInt8(maskComponents[2]),
              let maskOctet4 = UInt8(maskComponents[3]) else {
            return nil
        }
        
        // Calculate broadcast using logical operations: IP OR (NOT Mask)
        let broadcastOctet1 = octet1 | ~maskOctet1
        let broadcastOctet2 = octet2 | ~maskOctet2
        let broadcastOctet3 = octet3 | ~maskOctet3
        let broadcastOctet4 = octet4 | ~maskOctet4
        
        return "\(broadcastOctet1).\(broadcastOctet2).\(broadcastOctet3).\(broadcastOctet4)"
    }
    
    public func getCurrentBroadcastAddress() -> String? {
        // Get current WiFi interface IP address
        guard let ipAddress = getCurrentWiFiIPAddress(),
              let subnetMask = getSubnetMask() else {
            return nil
        }
        
        return getBroadcastAddress(forIP: ipAddress, withSubnetMask: subnetMask)
    }
}
