//
//  SideMenuView.swift
//  TestAuth
//
//  Created by Siriiii on 7/10/25.
//
import SwiftUI

struct SideMenuView: View {
    @Binding var isOpen: Bool
    let logoutAction: () async throws -> Void

    var body: some View {
        ZStack {
            // Scrim behind menu
            Color.black.opacity(isOpen ? 0.15 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isOpen = false }
                }

            // The menu itself
            HStack {
                Spacer()

                ZStack {
                    Color.white
                        .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 25.0) {
                        // Close button
                        HStack {
                            Spacer()
                            Button {
                                withAnimation { isOpen = false }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .padding()
                            }
                        }

                        // Menu items
                        Group {
                            SideMenuButton("Edit Profile") { /* TODO */ }
                            SideMenuButton("Friends") { /* TODO */ }
                            SideMenuButton("Friend Requests") { /* TODO */ }
                            SideMenuButton("Bracelet") { /* TODO */ }
                            SideMenuButton("Settings") { /* TODO */ }
                            SideMenuButton("Logout") {
                                Task {
                                    defer { withAnimation { isOpen = false } }
                                    do { try await logoutAction() }
                                    catch { print("Logout failed:", error) }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 50.0)
                    .padding(.horizontal, 25.0)
                }
                .frame(width: UIScreen.main.bounds.width * 0.70)
                // Slide in/out by adjusting offset
                .offset(x: isOpen ? 0 : UIScreen.main.bounds.width)
            }
        }
        
    }
}

private struct SideMenuButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title; self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        Divider()
    }
}


struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(isOpen: .constant(true), logoutAction: { })
    }
}
