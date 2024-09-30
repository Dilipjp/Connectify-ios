//
//  EditProfileView.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//


import SwiftUI

struct EditProfileView: View {
    @Binding var username: String
    @Binding var userBio: String
    @Binding var profileImage: UIImage?
    var saveAction: () -> Void
    var onSuccess: (String) -> Void
    
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var successMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Image Section
                VStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                            .shadow(radius: 10)
                            .onTapGesture {
                                isImagePickerPresented = true
                            }
                    } else {
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            VStack {
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                                Text("Select Profile Image")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.top)

                // Edit Info Section
                Form {
                    Section(header: Text("Edit Info").font(.headline)) {
                        TextField("Username", text: $username)
                        TextField("Bio", text: $userBio)
                    }
                }

                // Save Button
                Button(action: {
                    isLoading = true
                    saveAction()
                    onSuccess("Profile updated successfully!")
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        successMessage = nil
                    }
                }) {
                    Text(isLoading ? "Saving..." : "Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isLoading)

                // Success Message
                if let successMessage = successMessage {
                    Text(successMessage)
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .padding()
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $profileImage)
            }
        }
    }
}




