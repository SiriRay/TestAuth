//
//  CreateProfileView.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//

import SwiftUI
import FirebaseAuth

// A helper ViewModifier for our text field style
struct CustomTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(15)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CreateProfileView: View {
  @Binding var showCreateProfile: Bool
  @Binding var isAuthenticated: Bool
  @StateObject private var vm = CreateProfileViewModel()

  var body: some View {
      ZStack {
          // Background color
          Color(UIColor.systemGray6).ignoresSafeArea()
          
          ScrollView {
              VStack(spacing: 20) {
                  Text("CREATE PROFILE")
                      .font(.title).fontWeight(.heavy).multilineTextAlignment(.center).bold().padding(25.0)
                  
                  // MARK: - Profile Image Section
                  ProfileImagePicker(profileImage: $vm.profileImage, showImagePicker: $vm.showImagePicker)
                      .padding(.vertical, 15.0)

                  // MARK: - Form Fields
                  VStack(spacing: 20) {
                      TextField("First Name*", text: $vm.firstName)
                           .modifier(CustomTextFieldStyle())
                          .onChange(of: vm.firstName) { newValue in
                              // keep only A–Z or a–z
                              vm.firstName = String(newValue.filter { $0.isLetter })
                          }

                       TextField("Last Name*", text: $vm.lastName)
                           .modifier(CustomTextFieldStyle())
                         .onChange(of: vm.lastName) { newValue in
                             vm.lastName = String(newValue.filter { $0.isLetter })
                          }

                      // MARK: - Username Section
                      VStack(alignment: .leading, spacing: 5) {
                          TextField("Username*", text: $vm.username)
                              .autocapitalization(.none)
                              .disableAutocorrection(true)
                              .modifier(CustomTextFieldStyle())
                          
                          usernameStatusView()
                      }
                      
                      // MARK: - Phone Number Display
                      HStack {
                          Text(Auth.auth().currentUser?.phoneNumber ?? "No phone number")
                              .foregroundColor(.black.opacity(0.5))
                          Spacer()
                          Image(systemName: "checkmark.circle.fill")
                              .foregroundColor(.blue)
                      }
                      .modifier(CustomTextFieldStyle())

                  }
                  
                  Spacer()
                  
                  // MARK: - Action Button
                  if vm.isSaving {
                      ProgressView()
                          .frame(height: 50)
                  } else {
                      Button("Create Profile") {
                          vm.saveProfile()
                      }
                      .font(.headline)
                      .foregroundColor(.white)
                      .frame(height: 55)
                      .frame(maxWidth: 225)
                      .background(Color(red: 0.4, green: 0, blue: 0.05)) // Dark red/maroon
                      .cornerRadius(30)
                      .disabled(!vm.isFormValid)
                      .opacity(!vm.isFormValid ? 0.6 : 1.0)
                  }
                  
                  if let err = vm.errorMessage {
                      Text(err)
                          .foregroundColor(.red)
                          .multilineTextAlignment(.center)
                          .padding(.top, 5)
                  }
              }
              .padding(.horizontal, 24)
              .padding(.bottom, 15)
          }
      }
      // ─── BACK BUTTON OVERLAY ─────────────────────────────────────────
      .overlay(
        Button(action: {
          showCreateProfile = false
        }) {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
            Text("Back")
          }
          .padding(12)
        },
        alignment: .topLeading
      )
      .sheet(isPresented: $vm.showImagePicker) {
          ImagePickerView(image: $vm.profileImage)
      }
      .onChange(of: vm.didSaveProfile) {
          if vm.didSaveProfile {
              isAuthenticated   = true
              showCreateProfile = false
          }
      }
  }

    // --- START OF UPDATED BLOCK ---
    @ViewBuilder
    private func usernameStatusView() -> some View {
      HStack(alignment: .top) {
        // pick gray for "Checking…", green for available, red otherwise
        let messageColor: Color = {
          if vm.usernameMessage == "Checking…" { return .gray }
          if vm.isUsernameAvailable == true  { return .green }
          return .red
        }()
        
        Text(vm.usernameMessage)
          .font(.caption)
          .foregroundColor(messageColor)
        
        Spacer()
        
        if !vm.suggestedUsername.isEmpty && vm.username != vm.suggestedUsername {
          Button {
            vm.username = vm.suggestedUsername
          } label: {
            Text("Suggested: \(vm.suggestedUsername)")
              .font(.caption)
              .foregroundColor(.gray)
              .multilineTextAlignment(.trailing)
          }
        }
      }
      .frame(minHeight: 36)
      .padding(.horizontal, 8.0)
    }
    // --- END OF UPDATED BLOCK ---
}

// MARK: - Reusable Profile Image Picker View
struct ProfileImagePicker: View {
    @Binding var profileImage: UIImage?
    @Binding var showImagePicker: Bool
    
    var body: some View {
        Button(action: { showImagePicker = true }) {
            ZStack(alignment: .bottomTrailing) {
                // Main Image Display
                if let img = profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    // Placeholder
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 130, height: 130)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                
                // Edit Icon
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 35, height: 35)
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 2, y: 2)
            }
        }
    }
}

#Preview {
    CreateProfileView(
        showCreateProfile: .constant(true),
        isAuthenticated: .constant(false)
    )
}
