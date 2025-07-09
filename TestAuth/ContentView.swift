import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var phoneNumber: String = ""
    @State private var verificationID: String?
    @State private var verificationCode: String = ""
    @State private var isVerificationSent: Bool = false
    @State private var errorMessage: String?
    @Binding var isAuthenticated: Bool
    @Binding var showCreateProfile: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("1234567890", text: $phoneNumber)
                .placeholder(when: phoneNumber.isEmpty) {
                    Text("1234567890").foregroundColor(.gray)
                }
                .keyboardType(.phonePad)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
            
            Button("Send OTP") {
                sendVerificationCode()
            }
            .disabled(phoneNumber.count < 10)
            .padding()
            .buttonStyle(.borderedProminent)
            
            TextField("Verification code", text: $verificationCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .disabled(!isVerificationSent)
            
            Button("Verify Code") {
                verifyCode()
            }
            .disabled(!isVerificationSent || verificationCode.count < 4)
            .padding()
            .buttonStyle(.borderedProminent)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private func sendVerificationCode() {
        let formatted = "+1\(phoneNumber)"
        PhoneAuthProvider.provider().verifyPhoneNumber(formatted, uiDelegate: nil) { id, error in
            if let err = error as NSError? {
                print("Error sending OTP:", err)
                errorMessage = err.localizedDescription
                return
            }
            verificationID = id
            isVerificationSent = true
            errorMessage = nil
        }
    }
    
    private func verifyCode() {
        guard let vid = verificationID else { return }
        let credential = PhoneAuthProvider.provider()
            .credential(
                withVerificationID: vid,
                verificationCode: verificationCode
            )
        Auth.auth().signIn(with: credential) { result, error in
            if let err = error {
                errorMessage = err.localizedDescription
                return
            }
            
            // **HERE**: get the phone that we just verified
            guard let phone = Auth.auth().currentUser?.phoneNumber else {
                errorMessage = "Unable to retrieve your verified phone."
                return
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(phone).getDocument { snapshot, err in
                if let data = snapshot?.data(), !data.isEmpty {
                    // existing user → take them to Home
                    isAuthenticated = true
                    showCreateProfile = false
                } else {
                    // new user → show create profile flow
                    showCreateProfile = true
                }
            }
        }
    }
}
