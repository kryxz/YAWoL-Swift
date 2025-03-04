import Foundation
import Darwin

@_silgen_name("htons")
func htons(_ value: UInt16) -> UInt16

public class WakeOnLan {
    
    public enum WakeError: Error {
        case socketSetupFailed(reason: String)
        case setSocketOptionsFailed(reason: String)
        case sendMagicPacketFailed(reason: String)
        case invalidBroadcastAddress(reason: String)
        case invalidDevice(reason: String)
    }
    
    // MARK: - Public API
    
    /// This version lets you explicitly pass an IP, subnet mask, and port.
    /// It uses the NetworkConfigurationService to calculate the broadcast.
    public static func send(to device: WOLDevice, subnetMask: String) -> Result<Void, WakeError> {
        // Create or inject the NetworkConfigurationService
        let networkService = NetworkConfigurationService()

        // Validate MAC and IP
        guard
            let macAddress = device.macAddress,
            let ipAddress = device.ipAddress,
            !macAddress.isEmpty,
            macAddress.isValidMacAddress,  // <-- Make sure it's .isValidMacAddress (not the negation)
            !ipAddress.isEmpty
        else {
            return .failure(.invalidDevice(reason: "MAC or IP is missing/invalid"))
        }

        // Figure out port (default if 0).
        let port = device.port == 0 ? Constants.defaultPort : device.port

        // Use the service to get a broadcast address (instead of the old calculateBroadcastAddress)
        guard let broadcastAddress = networkService.getBroadcastAddress(forIP: ipAddress,
                                                                        withSubnetMask: subnetMask)
        else {
            return .failure(.invalidBroadcastAddress(reason: "Could not calculate broadcast address"))
        }

        return sendMagicPacket(macAddress: macAddress,
                               broadcastAddress: broadcastAddress,
                               port: port)
    }
    
    /// This version will figure out the current Wi-Fi IP, subnet mask, and broadcast
    /// if the device doesn’t provide them.
    public static func send(to device: WOLDevice) -> Result<Void, WakeError> {
        let networkService = NetworkConfigurationService()
        
        // If the device doesn’t have its own IP, we’ll attempt to get the current Wi-Fi IP
        // and then build the broadcast. Otherwise, we just use the IP + subnet mask approach.
        
        // 1. Get the subnet mask (if we don’t have it from the device).
        guard let subnet = networkService.getSubnetMask() else {
            return .failure(.invalidBroadcastAddress(reason: "Could not determine subnet mask"))
        }
        
        // 2. If device has an IP, use it; otherwise use our current Wi-Fi IP address.
        var ipAddress = device.ipAddress
        if ipAddress == nil || ipAddress?.isEmpty == true {
            ipAddress = networkService.getCurrentWiFiIPAddress()
        }
        
        // 3. If after all that, we still don’t have an IP, fail.
        guard let finalIPAddress = ipAddress else {
            return .failure(.invalidDevice(reason: "No valid IP address found."))
        }
        
        // 4. Now that we have a known IP + subnet, get broadcast.
        guard let broadcastAddress = networkService
            .getBroadcastAddress(forIP: finalIPAddress, withSubnetMask: subnet)
        else {
            return .failure(.invalidBroadcastAddress(reason: "Could not determine broadcast address"))
        }
        
        // 5. Validate MAC
        guard
            let macAddress = device.macAddress,
            !macAddress.isEmpty,
            macAddress.isValidMacAddress
        else {
            return .failure(.invalidDevice(reason: "MAC address is missing or invalid"))
        }
        
        // 6. Determine port
        let port = device.port == 0 ? Constants.defaultPort : device.port
        
        
        print("""
              Preparing to send WOL packet:
              MAC: \(macAddress)
              IP: \(finalIPAddress)
              Subnet: \(subnet)
              Broadcast: \(broadcastAddress)
              Port: \(port)
              """)
        
        // 7. Send out the magic packet
        return sendMagicPacket(macAddress: macAddress,
                               broadcastAddress: broadcastAddress,
                               port: port)
    }
    
    // MARK: - Private Helpers
    
    /// Opens a UDP socket, configures broadcast, and sends the magic packet.
    private static func sendMagicPacket(macAddress: String,
                                        broadcastAddress: String,
                                        port: Int16) -> Result<Void, WakeError> {
        
        let sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        if sock < 0 {
            return .failure(.socketSetupFailed(
                reason: String(cString: strerror(errno))
            ))
        }
        
        // Prepare target address
        var target = sockaddr_in()
        target.sin_family = sa_family_t(AF_INET)
        target.sin_addr.s_addr = inet_addr(broadcastAddress)
        target.sin_port = htons(UInt16(port))

        // Enable broadcast on the socket
        var broadcastEnable: Int32 = 1
        if setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcastEnable,
                      socklen_t(MemoryLayout<Int32>.size)) == -1 {
            close(sock)
            return .failure(.setSocketOptionsFailed(
                reason: String(cString: strerror(errno))
            ))
        }
        
        // Build the magic packet (6x 0xFF + 16x MAC)
        let packet = createMagicPacket(mac: macAddress)

        // Send it
        var targetCopy = target
        let sentBytes = withUnsafePointer(to: &targetCopy) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addrPtr in
                sendto(sock, packet, packet.count, 0,
                       addrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        close(sock)
        
        // Validate the number of bytes actually sent
        guard sentBytes == packet.count else {
            return .failure(.sendMagicPacketFailed(reason: "Incomplete packet sent"))
        }
        
        return .success(())
    }

    /// Creates the standard WOL Magic Packet
    private static func createMagicPacket(mac: String) -> [UInt8] {
        // 6 bytes of 0xFF
        var packet = [UInt8](repeating: 0xFF, count: 6)
        
        // Convert the MAC address (e.g. "AA:BB:CC:DD:EE:FF") to bytes
        let components = mac.split(separator: ":").compactMap { UInt8($0, radix: 16) }
        guard components.count == 6 else {
            // Invalid MAC -> empty packet
            return []
        }
        
        // Append the MAC address 16 times
        for _ in 0..<16 {
            packet.append(contentsOf: components)
        }
        return packet
    }
}
