//
//  DataDeletionView.swift
//  TestAuth
//
//  Created by Siriiii on 7/11/25.
//

import SwiftUI

struct DataDeletionView: View {
    @StateObject private var viewModel = DataDeletionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                if viewModel.isDeleting {
                    deletionInProgressView
                } else {
                    deletionInfoView
                }
                
                Spacer()
            }
        }
        .alert("Delete All Data", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDeletion()
            }
            Button("Delete", role: .destructive) {
                viewModel.executeDataDeletion()
            }
        } message: {
            Text("This will permanently delete all your data including your profile, friends, and account. This action cannot be undone.")
        }
        .alert("Deletion Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onChange(of: viewModel.didCompleteDataDeletion) { completed in
            if completed {
                // Navigate back to login/onboarding
                dismiss()
            }
        }
    }
    
    private var header: some View {
        ZStack {
            // Layer 1: The centered title
            HStack {
                Spacer()
                Text("Delete My Data")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Layer 2: The "Back" button, aligned to the left
            HStack {
                Button("Back") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .disabled(viewModel.isDeleting)
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var deletionInfoView: some View {
        VStack(spacing: 30) {
            // Warning Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .padding(.top, 60)
            
            // Title
            Text("Permanently Delete All Data")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            VStack(alignment: .leading, spacing: 15) {
                Text("This action will permanently delete:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // --- MODIFIED LIST ---
                deletionItem(icon: "person.circle.fill", text: "Your profile information")
                deletionItem(icon: "person.3.fill", text: "Your friends list")
                deletionItem(icon: "iphone.gen1", text: "Your phone number and authentication")
                deletionItem(icon: "icloud.fill", text: "All data stored in our servers")
                
                Text("This action cannot be undone.")
                    .font(.callout)
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            
            // Delete Button
            Button("Delete My Data") {
                viewModel.requestDataDeletion()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(width: 225.0, height: 50)
            .background(Color.red)
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    private var deletionInProgressView: some View {
        VStack(spacing: 40) {
            // Loading indicator
            ProgressView()
                .scaleEffect(2)
                .tint(.white)
                .padding(.top, 100)
            
            // Status text
            VStack(spacing: 10) {
                Text("Deleting Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(viewModel.deletionStep)
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            
            // Warning text
            Text("Please don't close the app while deletion is in progress.")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func deletionItem(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.red)
                .frame(width: 25)
            
            Text(text)
                .font(.callout)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    DataDeletionView()
}
