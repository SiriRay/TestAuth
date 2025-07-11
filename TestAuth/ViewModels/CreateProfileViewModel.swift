// ProfileViewModel.swift
// TestAuth
//
// Created by Siriiii on 7/10/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import Combine

/// Handles picking & uploading profile + Firestore write
class CreateProfileViewModel: ObservableObject {
  // MARK: — Inputs
  @Published var firstName    = ""
  @Published var lastName     = ""
  @Published var username     = ""      // raw input, no live stripping
  @Published var profileImage: UIImage?

  // MARK: — UI State
  @Published var showImagePicker      = false
  @Published var isSaving             = false
  @Published var errorMessage: String?

  // MARK: — Username Availability
  @Published var usernameMessage      = ""
  @Published var isUsernameAvailable: Bool? = nil
  @Published var suggestedUsername    = ""

  // MARK: — Outputs
  @Published var didSaveProfile = false

  private let db = Firestore.firestore()
  private var cancellables = Set<AnyCancellable>()

  private var phone: String {
    Auth.auth().currentUser?.phoneNumber ?? ""
  }

  var isFormValid: Bool {
    !firstName.isEmpty &&
    !lastName.isEmpty &&
    !username.isEmpty &&
    profileImage != nil &&
    isUsernameAvailable == true
  }

  init() {
    setupDebouncedUsernameCheck()
    setupSuggestionGenerator()
  }

  // MARK: — Debounced validation & availability check
  private func setupDebouncedUsernameCheck() {
    $username
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] raw in
        guard let self = self else { return }

        // 1) Reject anything with a non-alphanumeric
        if raw.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil {
          self.usernameMessage      = "Usernames can only contain letters and digits."
          self.isUsernameAvailable  = false
          return
        }

        // 2) Enforce min length
        if raw.count < 4 {
          self.usernameMessage      = "Username must be at least 4 characters."
          self.isUsernameAvailable  = false
          return
        }

        // 3) Fire off the Firestore check
        self.checkUsernameAvailability(username: raw)
      }
      .store(in: &cancellables)
  }

  private func setupSuggestionGenerator() {
    Publishers.CombineLatest($firstName, $lastName)
      .sink { [weak self] first, last in
        guard let self = self else { return }
        if !first.isEmpty || !last.isEmpty {
          let suffix = Int.random(in: 100...999)
          self.suggestedUsername = "\(first)\(last)\(suffix)"
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
          self.suggestedUsername = ""
        }
      }
      .store(in: &cancellables)
  }

  private func checkUsernameAvailability(username: String) {
    self.isUsernameAvailable = nil
    self.usernameMessage     = "Checking…"

    let candidate = username.lowercased()
    db.collection("users")
      .whereField("username", isEqualTo: candidate)
      .getDocuments { [weak self] snap, err in
        guard let self = self else { return }
        if let err = err {
          self.usernameMessage     = "Error: \(err.localizedDescription)"
          self.isUsernameAvailable = false
        } else if snap?.documents.isEmpty == true {
          self.usernameMessage     = "Username is available!"
          self.isUsernameAvailable = true
        } else {
          self.usernameMessage     = "Username is already taken."
          self.isUsernameAvailable = false
        }
      }
  }

  // MARK: — Profile Saving (unchanged)
  func saveProfile() {
    guard let imgData = profileImage?.jpegData(compressionQuality: 0.8) else {
      errorMessage = "Please select a profile image."
      return
    }
    guard let uid = Auth.auth().currentUser?.uid, !phone.isEmpty else {
      errorMessage = "User phone number not found. Please sign in again."
      return
    }

    isSaving = true
    errorMessage = nil

    let storageRef = Storage.storage()
      .reference()
      .child("profiles/\(uid).jpg")

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
          "uid": uid,
          "firstName": self.firstName,
          "lastName": self.lastName,
          "username": self.username.lowercased(),
          "phone": self.phone,
          "profileURL": downloadURL.absoluteString
        ]
        self.db.collection("users")
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
