//
//  SettingsMenuView.swift
//  TestAuth
//
//  Created by Siriiii on 7/11/25.
//

import SwiftUI

struct SettingsMenuView: View {
    @State private var showDataDeletionView = false
    
    var body: some View {
        Group {
            NavBarLists("Privacy Notice") { /*…*/ }
            NavBarLists("About App") { /*…*/ }
            NavBarLists("Permanently Delete My Data",
                        color: Color(hue: 1.0, saturation: 0.968, brightness: 0.743)) {
                showDataDeletionView = true
            }
            NavBarLists("Block List") { /*…*/ }
            NavBarLists("Help") { /*…*/ }
        }
        .sheet(isPresented: $showDataDeletionView) {
            DataDeletionView()
        }
    }
}

struct SettingsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        // A simple preview wrapper to see the list
        VStack(alignment: .leading, spacing: 25) {
            SettingsMenuView()
            Spacer()
        }
        .padding()
    }
}
