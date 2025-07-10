
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct RootView: View {
  @State private var isAuthenticated = (Auth.auth().currentUser != nil)
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
          isAuthenticated:    $isAuthenticated,
          showCreateProfile:  $showCreateProfile
        )
      }
    }
    .onAppear {
      // 1️⃣ Check Firestore for a user doc:
      if let phone = Auth.auth().currentUser?.phoneNumber {
        let docRef = Firestore.firestore()
          .collection("users")
          .document(phone)
        docRef.getDocument { snap, _ in
          if snap?.exists == true {
            isAuthenticated = true
          } else {
            showCreateProfile = true
          }
        }
      }
      // 2️⃣ Also listen for sign-out
      Auth.auth().addStateDidChangeListener { _, user in
        if user == nil {
          isAuthenticated = false
          showCreateProfile = false
        }
      }
    }
  }
}

#Preview {
    RootView()
}

