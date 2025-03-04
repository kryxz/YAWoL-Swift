//
//  AppError.swift
//  YAWoL
//
//  Created by kryx on 2025/03/02.
//


import Foundation

public enum AppError: Error {
    case invalidMacAddress(String)
    case networkUnavailable
    case packetSendFailed(reason: String)
    case subnetMaskNotFound
    case unknown(reason: String)

    public var userFriendlyMessage: String {
        switch self {
        case .invalidMacAddress(let address):
            return "Invalid MAC address: \(address)"
        case .networkUnavailable:
            return "Network is unavailable. Ensure you're connected to Wi-Fi."
        case .packetSendFailed(let reason):
            return "Failed to wake device: \(reason)"
        case .subnetMaskNotFound:
            return "Unable to determine subnet mask. Please check network settings."
        case .unknown(let reason):
            return "An unknown error occurred: \(reason)"
        }
    }
}
