import SwiftUI
import FirebaseAuth

struct MainDashboardView: View {
    @State private var isMenuOpen = false

    var body: some View {
        NavigationView {
            ZStack {
                // — Main Content, now vertically centered —
                VStack {
                    Spacer()       // push content down
                    Text("hello world")
                        .font(.largeTitle)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    Spacer()       // push content up
                }
                .disabled(isMenuOpen)

                // — Side Menu Overlay —
                SideMenuView(isOpen: $isMenuOpen, logoutAction: logout)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isMenuOpen {
                        Button {
                            withAnimation { isMenuOpen = true }
                        } label: {
                            Image(systemName: "line.horizontal.3")
                                .imageScale(.large)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
    }

    func logout() async throws {
        try Auth.auth().signOut()
    }
}

struct MainDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        MainDashboardView()
    }
}


#Preview {
    MainDashboardView()
}
