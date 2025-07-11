import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
  @Binding var isPresented: Bool
  @StateObject private var vm = EditProfileViewModel()

  var body: some View {
    NavigationView {
      ZStack {
        Color(UIColor.systemGray6).ignoresSafeArea()
        ScrollView {
          VStack(spacing: 20) {
            Text("EDIT PROFILE")
              .font(.title).fontWeight(.heavy).padding(.top, 25)

            // Profile image picker
            ProfileImagePicker(
              profileImage: $vm.profileImage,
              showImagePicker: $vm.showImagePicker
            )
            .padding(.vertical, 15)

            VStack(spacing: 20) {
              TextField("First Name*", text: $vm.firstName)
                .modifier(CustomTextFieldStyle())

              TextField("Last Name*", text: $vm.lastName)
                .modifier(CustomTextFieldStyle())

              VStack(alignment: .leading, spacing: 5) {
                TextField("Username*", text: $vm.username)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .modifier(CustomTextFieldStyle())
                usernameStatusView()
              }

              // Phone is read-only
              HStack {
                Text(Auth.auth().currentUser?.phoneNumber ?? "")
                  .foregroundColor(.black.opacity(0.5))
                Spacer()
                Image(systemName: "lock.fill")
                  .foregroundColor(.gray)
              }
              .modifier(CustomTextFieldStyle())
            }

            Spacer()

            if vm.isSaving {
              ProgressView().frame(height: 50)
            } else {
              Button("Save") {
                vm.saveProfile()
              }
              .font(.headline)
              .foregroundColor(.white)
              .frame(height: 55)
              .frame(maxWidth: 225)
              .background(Color(red: 0.4, green: 0, blue: 0.05))
              .cornerRadius(30)
              .disabled(!vm.isFormValid)
              .opacity(vm.isFormValid ? 1 : 0.6)
            }

            if let err = vm.errorMessage {
              Text(err)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 25)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { isPresented = false }
        }
      }
      // use the new onChange signature (zero-arg)
      .onChange(of: vm.didUpdateProfile) {
        if vm.didUpdateProfile {
          isPresented = false
        }
      }
      .sheet(isPresented: $vm.showImagePicker) {
        ImagePickerView(image: $vm.profileImage)
      }
    }
  }

  @ViewBuilder
  private func usernameStatusView() -> some View {
    HStack(alignment: .top) {
      let color: Color = {
        if vm.usernameMessage == "Checking…"   { return .gray }
        if vm.isUsernameAvailable == true     { return .green }
        return .red
      }()
      Text(vm.usernameMessage)
        .font(.caption)
        .foregroundColor(color)
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
    .padding(.horizontal, 8)
  }
}

// SwiftUI Preview
#Preview {
    EditProfileView(isPresented: .constant(true))
}
