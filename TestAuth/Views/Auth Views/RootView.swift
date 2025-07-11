//
//  RootView.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct RootView: View {
    // Watch for background/foreground transitions
    @Environment(\.scenePhase) private var scenePhase

    // Only true once both Firebase Auth and the Firestore "users" doc exist
    @State private var isAuthenticated   = false
    @State private var showCreateProfile = false

    var body: some View {
        VStack {
            if isAuthenticated {
                MainDashboardView()
            }
            else if showCreateProfile {
                CreateProfileView(
                    showCreateProfile: $showCreateProfile,
                    isAuthenticated:   $isAuthenticated
                )
            }
            else {
                LoginOrSignupView(
                    isAuthenticated:   $isAuthenticated,
                    showCreateProfile: $showCreateProfile
                )
            }
        }
        .onAppear {
            // 1️⃣ Initial check: if there's a logged-in user, verify their Firestore profile
            if let user = Auth.auth().currentUser,
               let phone = user.phoneNumber {
                Firestore.firestore()
                    .collection("users")
                    .document(phone)
                    .getDocument { snap, _ in
                        if let exists = snap?.exists, exists {
                            // Auth + profile both present
                            isAuthenticated   = true
                            showCreateProfile = false
                        } else {
                            // Auth only → force profile creation
                            isAuthenticated   = false
                            showCreateProfile = true
                        }
                    }
            }

            // 2️⃣ Re-run the same logic on every Auth state change (login/logout)
            Auth.auth().addStateDidChangeListener { _, user in
                guard let user = user,
                      let phone = user.phoneNumber else {
                    // fully signed out
                    isAuthenticated   = false
                    showCreateProfile = false
                    return
                } 
                Firestore.firestore()
                    .collection("users")
                    .document(phone)
                    .getDocument { snap, _ in
                        if let exists = snap?.exists, exists {
                            isAuthenticated   = true
                            showCreateProfile = false
                        } else {
                            isAuthenticated   = false
                            showCreateProfile = true
                        }
                    }
            }
        }
        // 3️⃣ If you back-out of CreateProfile early, delete the auth user completely
        .onChange(of: showCreateProfile) {
                   if showCreateProfile == false
                      && isAuthenticated == false
                      && Auth.auth().currentUser != nil {
                       deleteAuthUserCompletely()
                   }
               }
               // 4️⃣ Update onChange to use the new two-parameter syntax
               .onChange(of: scenePhase) { _, newPhase in
                   if newPhase == .background,
                      showCreateProfile && !isAuthenticated,
                      Auth.auth().currentUser != nil {
                       deleteAuthUserCompletely()
                   }
               }
           }
    
    // Helper function to completely delete the Firebase Auth user
    private func deleteAuthUserCompletely() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.delete { error in
            if let error = error {
                print("❌ Error deleting auth user:", error.localizedDescription)
                // If deletion fails, still try to sign out as fallback
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("❌ Sign-out error:", error.localizedDescription)
                }
            } else {
                print("✅ Auth user deleted successfully")
            }
        }
    }
}

#Preview {
    RootView()
}
