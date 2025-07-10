//
//  CreateProfileView.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateProfileView: View {
  @Binding var showCreateProfile: Bool
  @Binding var isAuthenticated: Bool
  @StateObject private var vm = ProfileViewModel()

  var body: some View {
    VStack(spacing: 16) {
      TextField("First Name", text: $vm.firstName)
        .textFieldStyle(RoundedBorderTextFieldStyle())
      TextField("Last Name",  text: $vm.lastName)
        .textFieldStyle(RoundedBorderTextFieldStyle())

      HStack {
        TextField("Username", text: $vm.username)
          .autocapitalization(.none)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        Button("Suggest") {
          let suggestion = "\(vm.firstName)\(vm.lastName)\(Int.random(in: 100...999))"
          vm.username = suggestion.lowercased()
        }
      }

      Text("Phone: \(Auth.auth().currentUser?.phoneNumber ?? "")")
        .foregroundColor(.gray)

      if let img = vm.profileImage {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
          .frame(width: 100, height: 100)
          .clipShape(Circle())
      } else {
        Button("Select Photo") { vm.showImagePicker = true }
      }

      if vm.isSaving {
        ProgressView()
      } else {
        Button("Create Profile") { vm.saveProfile() }
          .disabled(!vm.isFormValid)
          .buttonStyle(.borderedProminent)
      }

      if let err = vm.errorMessage {
        Text(err).foregroundColor(.red).multilineTextAlignment(.center)
      }
    }
    .padding()
    .sheet(isPresented: $vm.showImagePicker) {
      ImagePickerView(image: $vm.profileImage)
    }
    // when save succeeds, dismiss & move to Home:
    .onChange(of: vm.didSaveProfile) { success in
      if success {
        isAuthenticated   = true
        showCreateProfile = false
      }
    }
  }
}


#Preview {
    // show the profile-creation screen
    CreateProfileView(
        showCreateProfile: .constant(true),
        isAuthenticated: .constant(false)
    )
}
