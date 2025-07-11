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
        // 3️⃣ If you back-out of CreateProfile early, sign you out immediately
        .onChange(of: showCreateProfile) { newValue in
            if newValue == false
               && isAuthenticated == false
               && Auth.auth().currentUser != nil {
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("❌ Sign-out error:", error.localizedDescription)
                }
            }
        }
        // 4️⃣ If you background/close the app while still in CreateProfile, sign you out too
        .onChange(of: scenePhase) { phase in
            if phase == .background,
               showCreateProfile && !isAuthenticated,
               Auth.auth().currentUser != nil {
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("❌ Sign-out error on background:", error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    RootView()
}
