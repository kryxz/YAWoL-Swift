//
//  DeviceWakeView.swift
//  YAWoL
//
//  Created by kryx on 2025/02/27.
//

import SwiftUI


struct DeviceWakeView: View {
    @ObservedObject var viewModel: DeviceViewModel

    var body: some View {
        VStack {
            Button(action: {
                viewModel.sendWOLPacket()
            })
            {
                Text("Wake \(viewModel.deviceName)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundColor(.white)
            }
            .foregroundColor(Color.green)
            .cornerRadius(8)
            .padding()

            Group {
                switch viewModel.sendStatus {
                case .idle:
                    EmptyView()
                case .sending:
                    Text("Sending...")
                        .foregroundColor(.blue)
                case .success:
                    Text("WOL packet sent successfully!")
                        .foregroundColor(.green)
                case .failure(let error):
                    Text("Failed to send WOL packet: \(error)")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}
