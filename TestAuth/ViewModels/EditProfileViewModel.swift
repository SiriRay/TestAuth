//
//  EditProfileViewModel.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

/// Handles loading, editing & saving an existing profile
class EditProfileViewModel: ObservableObject {
  // MARK: — Inputs
  @Published var firstName    = ""
  @Published var lastName     = ""
  @Published var username     = ""
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
  @Published var didUpdateProfile = false

  private let db = Firestore.firestore()
  private let storage = Storage.storage()
  private var cancellables = Set<AnyCancellable>()

  // Keep originals so we can skip availability check if unchanged
  private var originalFirstName = ""
  private var originalLastName = ""
  private var originalUsername = ""
  private var originalProfileURL: String?

  private var phone: String {
    Auth.auth().currentUser?.phoneNumber ?? ""
  }
  private var uid: String {
    Auth.auth().currentUser?.uid ?? ""
  }

  /// Only enable Save when something changed, form is valid, and username available
  var isFormValid: Bool {
    !firstName.isEmpty &&
    !lastName.isEmpty &&
    !username.isEmpty &&
    profileImage != nil &&
    isUsernameAvailable == true
  }

  init() {
    loadUserProfile()
    setupDebouncedUsernameCheck()
    setupSuggestionGenerator()
  }
    // MARK: — Local file-cache helpers
    private func profileImageCacheURL() -> URL? {
      let fm = FileManager.default
      guard let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first,
            let uid = Auth.auth().currentUser?.uid
      else { return nil }
      return dir.appendingPathComponent("profile_\(uid).jpg")
    }

    private func loadCachedProfileImage() -> UIImage? {
      guard let url = profileImageCacheURL(),
            let data = try? Data(contentsOf: url)
      else { return nil }
      return UIImage(data: data)
    }

    private func saveImageToCache(data: Data) {
      guard let url = profileImageCacheURL() else { return }
      try? data.write(to: url, options: .atomic)
    }


    private func loadUserProfile() {
      guard let phone = Auth.auth().currentUser?.phoneNumber,
            !phone.isEmpty else {
        print("✋ no authenticated user; skipping loadUserProfile")
        return
      }
      let docRef = db.collection("users").document(phone)

      // fires immediately with cached data, then again with server data
      docRef.addSnapshotListener { [weak self] snap, error in
        guard let self = self,
              let data = snap?.data(),
              !data.isEmpty else { return }

        // stash originals
        self.originalFirstName  = data["firstName"]  as? String ?? ""
        self.originalLastName   = data["lastName"]   as? String ?? ""
        let uname               = data["username"]   as? String ?? ""
        self.originalUsername   = uname.lowercased()
        self.originalProfileURL = data["profileURL"] as? String

        DispatchQueue.main.async {
          // populate text fields right away
          self.firstName = self.originalFirstName
          self.lastName  = self.originalLastName
          self.username  = self.originalUsername

          // **1️⃣** try to load the last-downloaded image from disk (instant!)
          if let img = self.loadCachedProfileImage() {
            self.profileImage = img
          }
        }

        // **2️⃣** then fetch the fresh image from Storage and overwrite + cache
        if let urlString = self.originalProfileURL,
           let url = URL(string: urlString) {
          let ref = self.storage.reference(forURL: url.absoluteString)
          ref.getData(maxSize: 5 * 1024 * 1024) { data, _ in
            guard let data = data,
                  let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async {
              self.profileImage = image
            }
            // save for next time
            self.saveImageToCache(data: data)
          }
        }
      }
    }


  private func setupDebouncedUsernameCheck() {
    $username
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] raw in
        guard let self = self else { return }
        let candidate = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Alphanumeric only
        if raw.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil {
          self.usernameMessage     = "Usernames can only contain letters and digits."
          self.isUsernameAvailable = false
          return
        }

        // Min length
        if raw.count < 4 {
          self.usernameMessage     = "Username must be at least 4 characters."
          self.isUsernameAvailable = false
          return
        }

        // If unchanged from original, treat as available
        if candidate == self.originalUsername {
          self.usernameMessage     = "Username unchanged."
          self.isUsernameAvailable = true
          return
        }

        // Otherwise hit Firestore
        self.checkUsernameAvailability(username: candidate)
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

    db.collection("users")
      .whereField("username", isEqualTo: username)
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

  func saveProfile() {
    guard let imgData = profileImage?.jpegData(compressionQuality: 0.8) else {
      errorMessage = "Please select a profile image."
      return
    }
    isSaving = true
    errorMessage = nil

    // overwrite the same storage path
    let profileRef = storage.reference().child("profiles/\(uid).jpg")
    profileRef.putData(imgData, metadata: nil) { [weak self] _, err in
      guard let self = self else { return }
      if let err = err {
        self.errorMessage = err.localizedDescription
        self.isSaving = false
        return
      }
      profileRef.downloadURL { url, err in
        if let err = err {
          self.errorMessage = err.localizedDescription
          self.isSaving = false
          return
        }
        guard let downloadURL = url else {
          self.errorMessage = "Unable to retrieve image URL."
          self.isSaving = false
          return
        }
        // update only the changed fields
        let updatedData: [String: Any] = [
          "firstName": self.firstName,
          "lastName":  self.lastName,
          "username":  self.username.lowercased(),
          "profileURL": downloadURL.absoluteString
        ]
        self.db.collection("users")
          .document(self.phone)
          .updateData(updatedData) { err in
            self.isSaving = false
            if let err = err {
              self.errorMessage = err.localizedDescription
            } else {
              self.didUpdateProfile = true
            }
          }
      }
    }
  }
}
