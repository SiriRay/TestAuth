import SwiftUI

struct NavBarView: View {
    @Binding var isOpen: Bool
    let logoutAction: () async throws -> Void

    @State private var showLogoutPopup = false
    private var menuWidth: CGFloat { UIScreen.main.bounds.width * 0.7 }

    var body: some View {
        ZStack {
            // 1) scrim behind menu
            Color.black.opacity(isOpen ? 0.15 : 0)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isOpen = false } }

            // 2) side‐menu itself
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 25) {
                    // close button
                    HStack {
                        Spacer()
                        Button { withAnimation { isOpen = false } } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding()
                        }
                    }

                    // your nav items
                    NavBarLists("Edit Profile")    { /* … */ }
                    NavBarLists("Friends")         { /* … */ }
                    NavBarLists("Friend Requests") { /* … */ }
                    NavBarLists("Bracelet")        { /* … */ }
                    NavBarLists("Settings")        { /* … */ }

                    // LOGOUT → show popup
                    NavBarLists("Logout") {
                        withAnimation { showLogoutPopup = true }
                    }

                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 25)
                .frame(width: menuWidth)
                .background(Color.white)
                // animate only this offset
                .offset(x: isOpen ? 0 : menuWidth)
            }

            // 3) centered logout confirmation popup
            if showLogoutPopup {
                // a stronger scrim behind the popup
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showLogoutPopup = false }

                LogoutAlertView(
                    confirmAction: {
                        Task {
                            defer {
                                withAnimation {
                                    showLogoutPopup = false
                                    isOpen = false
                                }
                            }
                            do { try await logoutAction() }
                            catch { print("Logout error:", error) }
                        }
                    },
                    cancelAction: {
                        withAnimation { showLogoutPopup = false }
                    }
                )
            }
        }
    }
}

private struct NavBarLists: View {
    let title: String
    let action: () -> Void

    init(_ title: String,
         action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)
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
