//
//  ContentView.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//


import SwiftUI

struct LoginOrSignupView: View {
  @Binding var isAuthenticated: Bool
  @Binding var showCreateProfile: Bool
  @StateObject private var vm = AuthViewModel()

  var body: some View {
    VStack(spacing: 20) {
      // … all your UI binding to vm.phoneNumber, vm.verificationCode, etc.
      TextField("1234567890", text: $vm.phoneNumber)
        .placeholder(when: vm.phoneNumber.isEmpty) { Text("1234567890").foregroundColor(.gray) }
        .keyboardType(.phonePad)
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

      Button("Send OTP")     { vm.sendVerificationCode() }
        .disabled(vm.phoneNumber.count < 10)
        .buttonStyle(.borderedProminent)

      TextField("Verification code", text: $vm.verificationCode)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .disabled(!vm.isVerificationSent)

      Button("Verify Code")  { vm.verifyCode() }
        .disabled(!vm.isVerificationSent || vm.verificationCode.count < 4)
        .buttonStyle(.borderedProminent)

      if let error = vm.errorMessage {
        Text(error).foregroundColor(.red).multilineTextAlignment(.center)
      }
    }
    .padding()
    // propagate VM outputs back up via the bindings:
    .onChange(of: vm.didAuthenticate) { oldValue, newValue in
        isAuthenticated = newValue
    }
    .onChange(of: vm.shouldShowCreateProfile) { _, newValue in
        showCreateProfile = newValue
    }
  }
}

#Preview {
    // start in the “not authenticated” flow
    LoginOrSignupView(
        isAuthenticated: .constant(false),
        showCreateProfile: .constant(false)
    )
}

