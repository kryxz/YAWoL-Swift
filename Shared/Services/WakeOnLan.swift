import Foundation
import Darwin

public class WakeOnLan {
    
    public struct Device {
        public let mac: String
        public let broadcastAddress: String
        public let port: Int16
        
        public init(mac: String, broadcastAddress: String, port: Int16 = 9) {
            self.mac = mac
            self.broadcastAddress = broadcastAddress
            self.port = port
        }
    }

    public enum WakeError: Error {
        case socketSetupFailed(reason: String)
        case setSocketOptionsFailed(reason: String)
        case sendMagicPacketFailed(reason: String)
        case invalidBroadcastAddress(reason: String)
    }
    
    public static func send(to device: Device) -> Result<Void, WakeError> {
        // Create UDP socket.
        let sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        if sock < 0 {
            let err = String(cString: strerror(errno))
            return .failure(.socketSetupFailed(reason: err))
        }
        
        // Prepare the target address.
        var target = sockaddr_in()
        target.sin_family = sa_family_t(AF_INET)
        
        // Determine the broadcast address to use.
        let broadcastStr: String
        if device.broadcastAddress.isEmpty || device.broadcastAddress == Constants.defaultBroadcastAddress {
            if let correctBroadcast = getCurrentBroadcastAddress() {
                broadcastStr = correctBroadcast
            } else {
                broadcastStr = device.broadcastAddress
            }
        } else {
            broadcastStr = device.broadcastAddress
        }
        
        // Resolve the broadcast address string.
        var bcaddr = inet_addr(broadcastStr)
        if bcaddr == INADDR_NONE {
            guard let host = gethostbyname(broadcastStr) else {
                close(sock)
                return .failure(.invalidBroadcastAddress(reason: "Unable to resolve broadcast address: \(broadcastStr)"))
            }
            memcpy(&bcaddr, host.pointee.h_addr_list[0], Int(host.pointee.h_length))
        }
        target.sin_addr.s_addr = bcaddr
        
        // Set the port (convert host to network byte order).
        target.sin_port = _OSSwapInt16(UInt16(device.port))
        
        // Create the magic packet.
        let packet = createMagicPacket(mac: device.mac)
        let sockaddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let optionSize = socklen_t(MemoryLayout<Int32>.size)
        
        // Enable broadcast on the socket.
        var broadcast: Int32 = 1
        if setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, optionSize) == -1 {
            close(sock)
            let err = String(cString: strerror(errno))
            print(err)
            return .failure(.setSocketOptionsFailed(reason: err))
        }
        
        // Send the magic packet.
        var targetCopy = target
        let sendResult = withUnsafePointer(to: &targetCopy) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addrPtr in
                sendto(sock, packet, packet.count, 0, addrPtr, sockaddrLen)
            }
        }
        
        if sendResult != packet.count {
            close(sock)
            let err = String(cString: strerror(errno))
            print(err)
            return .failure(.sendMagicPacketFailed(reason: err))
        }
        
        close(sock)
        return .success(())
    }
    
    
    private static func createMagicPacket(mac: String) -> [UInt8] {
        var packet = [UInt8]()
        // 6 bytes of 0xFF header.
        packet.append(contentsOf: [UInt8](repeating: 0xFF, count: 6))
        
        // Convert the MAC address string (expected format "AA:BB:CC:DD:EE:FF") into bytes.
        let components = mac.split(separator: ":")
        let macBytes = components.compactMap { UInt8($0, radix: 16) }
        guard macBytes.count == 6 else {
            // If the MAC address is invalid, return an empty packet.
            return []
        }
        
        // Append the MAC address 16 times.
        for _ in 0..<16 {
            packet.append(contentsOf: macBytes)
        }
        
        return packet
    }
    
    /// Calculates the broadcast address from the current Wi‑Fi interface (typically "en0").
    /// Returns a string in dotted decimal format (e.g. "192.168.1.255") if found.
    private static func getCurrentBroadcastAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            // We're interested in IPv4 addresses.
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                // Typically, the Wi‑Fi interface is "en0".
                if name == "en0" {
                    // Check if this interface supports broadcast.
                    if (Int32(interface.ifa_flags) & Int32(IFF_BROADCAST)) != 0,
                       let dstAddr = interface.ifa_dstaddr {
                        var addr = dstAddr.pointee
                        var sockAddr = withUnsafePointer(to: &addr) {
                            $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr }
                        }
                        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                        inet_ntop(AF_INET, &sockAddr, &buffer, socklen_t(INET_ADDRSTRLEN))
                        return String(cString: buffer)
                    }
                }
            }
        }
        return nil
    }
}
