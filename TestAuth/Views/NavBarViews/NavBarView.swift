import SwiftUI

struct NavBarView: View {
    @Binding var isOpen: Bool
    let logoutAction: () async throws -> Void

    @State private var showLogoutPopup = false
    @State private var showEditProfile = false
    @State private var showingSettings   = false

    private var menuWidth: CGFloat { UIScreen.main.bounds.width * 0.7 }

    var body: some View {
        ZStack {
            // 1) scrim behind menu
            Color.black.opacity(isOpen ? 0.15 : 0)
                .ignoresSafeArea()
                .onTapGesture { isOpen = false }

            // 2) side‐menu itself
            HStack {
                Spacer()

                VStack(alignment: .leading, spacing: 25) {
                    // ─── Top bar ───
                    HStack {
                        if showingSettings {
                            // back arrow on the left
                            Button {
                                // Removed withAnimation for an instant transition
                                showingSettings = false
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .padding(.leading, 2)
                            }
                        }
                        Spacer()
                        // always show the “×”
                        Button {
                            isOpen = false
                            // Reset settings state when closing menu
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingSettings = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding()
                        }
                    }
                    .frame(height: 30) // Give consistent height to prevent layout shifts


                    // ─── Menu content ───
                    if showingSettings {
                        // SETTINGS SUB-MENU (Now in a separate view)
                        SettingsMenuView()
                    } else {
                        // ROOT MENU
                        NavBarLists("Edit Profile") {
                            showEditProfile = true
                            isOpen = false
                        }
                        NavBarLists("Friends")         { /* … */ }
                        NavBarLists("Friend Requests") { /* … */ }
                        NavBarLists("Bracelet")        { /* … */ }
                        NavBarLists("Settings") {
                            // Removed withAnimation for an instant transition
                            showingSettings = true
                        }
                        NavBarLists("Logout") {
                            showLogoutPopup = true
                        }
                    }

                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 25)
                .frame(width: menuWidth)
                .background(Color.white)
                .offset(x: isOpen ? 0 : menuWidth)
                .animation(.easeInOut, value: isOpen) 
            }

            // 3) centered logout confirmation popup (unchanged)
            if showLogoutPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showLogoutPopup = false }

                LogoutAlertView(
                  confirmAction: {
                    Task {
                      defer {
                        showLogoutPopup = false
                        isOpen = false
                      }
                      do { try await logoutAction() }
                      catch { print("Logout error:", error) }
                    }
                  },
                  cancelAction: {
                    showLogoutPopup = false
                  }
                )
            }
        }
        // PRESENT EDIT-PROFILE SHEET (unchanged)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(isPresented: $showEditProfile)
        }
    }
}

// NOTE: Unchanged
struct NavBarLists: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(
      _ title: String,
      color: Color = .black,         // default = black
      action: @escaping () -> Void
    ) {
      self.title = title
      self.color = color
      self.action = action
    }

    var body: some View {
      Button(action: action) {
        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(color)       // use the passed‐in color
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      Divider()
    }
}


struct NavBarView_Previews: PreviewProvider {
    static var previews: some View {
        NavBarView(isOpen: .constant(true), logoutAction: { })
    }
}
