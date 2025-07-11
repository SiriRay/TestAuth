//
//  LogoutConfirmationView.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//


import SwiftUI

struct LogoutAlertView: View {
    let confirmAction: () -> Void
    let cancelAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Log Out")
                .font(.headline)
                .foregroundColor(.black)

            Text("Are you sure you want to log out?")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.8))
            
            Divider()

            HStack(spacing: 16) {
                Button("Cancel") {
                    cancelAction()
                }
                .font(.body)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)

                Button("Log Out") {
                    confirmAction()
                }
                .font(.body)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .frame(maxWidth: 300)
    }
}

struct LogoutConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutAlertView(
            confirmAction: { },
            cancelAction: { }
        )
        
    }
}
