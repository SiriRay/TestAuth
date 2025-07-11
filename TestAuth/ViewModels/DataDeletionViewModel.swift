//
//  DataDeletionViewModel.swift
//  TestAuth
//
//  Created by Siriiii on 7/11/25.
//


//
//  DataDeletionViewModel.swift
//  TestAuth
//
//  Created by Siriiii on 7/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

/// Handles permanent deletion of user data from all Firebase services
class DataDeletionViewModel: ObservableObject {
    // MARK: - UI State
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false
    @Published var deletionStep = ""
    
    // MARK: - Outputs
    @Published var didCompleteDataDeletion = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var phone: String {
        Auth.auth().currentUser?.phoneNumber ?? ""
    }
    
    private var uid: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    // MARK: - Public Methods
    
    /// Initiates the data deletion confirmation flow
    func requestDataDeletion() {
        showDeleteConfirmation = true
    }
    
    /// Executes the complete data deletion process
    func executeDataDeletion() {
        guard !phone.isEmpty, !uid.isEmpty else {
            errorMessage = "No authenticated user found."
            return
        }
        
        isDeleting = true
        errorMessage = nil
        showDeleteConfirmation = false
        
        // Execute deletion steps in sequence
        deleteUserData()
    }
    
    /// Cancels the deletion process
    func cancelDeletion() {
        showDeleteConfirmation = false
    }
    
    // MARK: - Private Methods
    
    /// Step 1: Delete user document from Firestore
    private func deleteUserData() {
        deletionStep = "Deleting user profile..."
        
        db.collection("users").document(phone).delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleDeletionError("Failed to delete user profile: \(error.localizedDescription)")
                return
            }
            
            // Continue to storage deletion
            self.deleteUserStorage()
        }
    }
    
    /// Step 2: Delete user's profile image from Storage
    private func deleteUserStorage() {
        deletionStep = "Deleting profile images..."
        
        let profileRef = storage.reference().child("profiles/\(uid).jpg")
        
        profileRef.delete { [weak self] error in
            guard let self = self else { return }
            
            // Continue even if storage deletion fails (file might not exist)
            if let error = error {
                print("⚠️ Storage deletion warning: \(error.localizedDescription)")
            }
            
            // Continue to cache cleanup
            self.deleteLocalCache()
        }
    }
    
    /// Step 3: Delete cached profile image from device
    private func deleteLocalCache() {
        deletionStep = "Clearing local cache..."
        
        // Delete cached profile image
        if let cacheURL = profileImageCacheURL() {
            try? FileManager.default.removeItem(at: cacheURL)
        }
        
        // Continue to authentication deletion
        deleteUserAuthentication()
    }
    
    /// Step 4: Delete user's authentication account
    private func deleteUserAuthentication() {
        deletionStep = "Deleting authentication account..."
        
        guard let currentUser = Auth.auth().currentUser else {
            handleDeletionError("No authenticated user found.")
            return
        }
        
        currentUser.delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleDeletionError("Failed to delete authentication account: \(error.localizedDescription)")
                return
            }
            
            // All deletion steps completed successfully
            self.completeDeletion()
        }
    }
    
    /// Handles successful completion of data deletion
    private func completeDeletion() {
        DispatchQueue.main.async {
            self.isDeleting = false
            self.deletionStep = ""
            self.didCompleteDataDeletion = true
        }
    }
    
    /// Handles deletion errors
    private func handleDeletionError(_ message: String) {
        DispatchQueue.main.async {
            self.isDeleting = false
            self.errorMessage = message
            self.deletionStep = ""
        }
    }
    
    /// Gets the cache URL for profile image
    private func profileImageCacheURL() -> URL? {
        let fm = FileManager.default
        guard let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return dir.appendingPathComponent("profile_\(uid).jpg")
    }
}