
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct CreateProfileView: View {
    @Binding var showCreateProfile: Bool
    @Binding var isAuthenticated: Bool

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var phone: String {
        Auth.auth().currentUser?.phoneNumber ?? ""
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !username.isEmpty && profileImage != nil
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Suggest") {
                    let suggestion = "\(firstName)\(lastName)\(Int.random(in: 100...999))"
                    username = suggestion.lowercased()
                }
            }

            Text("Phone: \(phone)")
                .foregroundColor(.gray)

            // Profile Image Picker
            if let img = profileImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Button("Select Photo") {
                    showImagePicker = true
                }
            }

            if isSaving {
                ProgressView()
            } else {
                Button("Create Profile") {
                    saveProfile()
                }
                .disabled(!isFormValid)
                .buttonStyle(.borderedProminent)
            }

            if let err = errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top)
            }
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
        }
    }

    private func saveProfile() {
        guard let imgData = profileImage?.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Please select a profile image."
            return
        }
        isSaving = true
        errorMessage = nil

        // 1. Upload image to Firebase Storage
        let storage = Storage.storage() // or Storage.storage(url: "gs://<your-bucket>.appspot.com")
        let storageRef = storage.reference().child("profiles/\(phone).jpg")

        print("🚀 Starting upload for profiles/\(phone).jpg")
        storageRef.putData(imgData, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ upload failed:", error)
                errorMessage = error.localizedDescription
                isSaving = false
                return
            }

            print("✅ upload succeeded, metadata:", metadata ?? "nil")

            // 2. Fetch download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("🔴 downloadURL failed:", error)
                    errorMessage = error.localizedDescription
                    isSaving = false
                    return
                }

                guard let downloadURL = url else {
                    print("⚠️ downloadURL was nil")
                    errorMessage = "Unable to retrieve image URL."
                    isSaving = false
                    return
                }

                print("🌐 Got download URL:", downloadURL.absoluteString)

                // 3. Save user profile in Firestore
                let userData: [String: Any] = [
                    "firstName": firstName,
                    "lastName": lastName,
                    "username": username,
                    "phone": phone,
                    "profileURL": downloadURL.absoluteString
                ]

                Firestore.firestore()
                    .collection("users")
                    .document(phone)
                    .setData(userData) { err in
                        isSaving = false
                        if let err = err {
                            print("Firestore write error:", err)
                            errorMessage = err.localizedDescription
                        } else {
                            print("🚀 Profile saved to Firestore")
                            isAuthenticated = true
                            showCreateProfile = false
                        }
                    }
            }
        }
    }
}

// Utility: placeholder modifier
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
