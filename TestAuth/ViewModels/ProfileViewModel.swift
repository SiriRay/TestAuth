//
//  ProfileViewModel.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

/// Handles picking & uploading profile + Firestore write
class ProfileViewModel: ObservableObject {
  // MARK: — Inputs
  @Published var firstName = ""
  @Published var lastName = ""
  @Published var username = ""
  @Published var profileImage: UIImage?
  
  // MARK: — UI State
  @Published var showImagePicker = false
  @Published var isSaving = false
  @Published var errorMessage: String?

  // MARK: — Outputs
  @Published var didSaveProfile = false

  private var phone: String {
    Auth.auth().currentUser?.phoneNumber ?? ""
  }

  var isFormValid: Bool {
    !firstName.isEmpty &&
    !lastName.isEmpty &&
    !username.isEmpty &&
    profileImage != nil
  }

  func saveProfile() {
    guard let imgData = profileImage?.jpegData(compressionQuality: 0.8) else {
      errorMessage = "Please select a profile image."
      return
    }
    isSaving = true
    errorMessage = nil

    let storageRef = Storage.storage()
      .reference()
      .child("profiles/\(phone).jpg")

    storageRef.putData(imgData, metadata: nil) { [weak self] _, error in
      guard let self = self else { return }
      if let error = error {
        self.errorMessage = error.localizedDescription
        self.isSaving = false
        return
      }

      storageRef.downloadURL { url, error in
        if let error = error {
          self.errorMessage = error.localizedDescription
          self.isSaving = false
          return
        }
        guard let downloadURL = url else {
          self.errorMessage = "Unable to retrieve image URL."
          self.isSaving = false
          return
        }

        let userData: [String: Any] = [
          "firstName": self.firstName,
          "lastName": self.lastName,
          "username": self.username,
          "phone": self.phone,
          "profileURL": downloadURL.absoluteString
        ]

        Firestore.firestore()
          .collection("users")
          .document(self.phone)
          .setData(userData) { err in
            self.isSaving = false
            if let err = err {
              self.errorMessage = err.localizedDescription
            } else {
              self.didSaveProfile = true
            }
          }
      }
    }
  }
}
