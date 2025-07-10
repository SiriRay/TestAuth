//
//  AuthViewModel.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Handles send/verify OTP and routes new vs existing users
class AuthViewModel: ObservableObject {
  // MARK: — Inputs
  @Published var phoneNumber = ""
  @Published var verificationCode = ""

  // MARK: — UI State
  @Published var isVerificationSent = false
  @Published var errorMessage: String?

  // MARK: — Outputs (to drive navigation)
  @Published var didAuthenticate = false
  @Published var shouldShowCreateProfile = false

  private var verificationID: String?

  func sendVerificationCode() {
    let formatted = "+1\(phoneNumber)"
    PhoneAuthProvider.provider().verifyPhoneNumber(formatted, uiDelegate: nil) { [weak self] id, error in
      guard let self = self else { return }
      if let err = error as NSError? {
        self.errorMessage = err.localizedDescription
        return
      }
      self.verificationID = id
      self.isVerificationSent = true
      self.errorMessage = nil
    }
  }

  func verifyCode() {
    guard let vid = verificationID else { return }
    let credential = PhoneAuthProvider.provider()
      .credential(withVerificationID: vid, verificationCode: verificationCode)

    Auth.auth().signIn(with: credential) { [weak self] _, error in
      guard let self = self else { return }
      if let err = error {
        self.errorMessage = err.localizedDescription
        return
      }

      guard let phone = Auth.auth().currentUser?.phoneNumber else {
        self.errorMessage = "Unable to retrieve your verified phone."
        return
      }

      let db = Firestore.firestore()
      db.collection("users").document(phone).getDocument { snapshot, _ in
        if let data = snapshot?.data(), !data.isEmpty {
          self.didAuthenticate = true
          self.shouldShowCreateProfile = false
        } else {
          self.shouldShowCreateProfile = true
        }
      }
    }
  }
}
