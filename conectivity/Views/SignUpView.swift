//
//  SignUpView.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import SwiftUI
import FirebaseStorage
import UIKit
struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var userName = ""
    @State private var userBio = ""
    @State private var selectedRole = "User" // Default role
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var successMessage = ""
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        VStack(spacing: 20) {
            Text("Create an Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)

            TextField("Email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            TextField("Username", text: $userName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            TextField("Bio", text: $userBio)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            // Role Selection
            Picker("Select Role", selection: $selectedRole) {
                Text("User").tag("User")
                Text("Moderator").tag("Moderator")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Profile Image Selection
            Button(action: {
                showImagePicker = true
            }) {
                Text("Select Profile Image")
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }

            if isLoading {
                ProgressView("Creating Account...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button(action: {
                    if password == confirmPassword {
                        isLoading = true
                        successMessage = "" // Clear previous success message
                        uploadProfileImageAndSignUp()
                    } else {
                        errorMessage = "Passwords do not match"
                    }
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }

            // Link to Sign In Page
            HStack {
                Text("Do you already have an account?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                NavigationLink(destination: SignInView()) {
                    Text("Sign In")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 20)

            if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private func uploadProfileImageAndSignUp() {
        guard let image = selectedImage else {
            // If no image is selected, use default URL
            let defaultProfileImageURL = "defaultProfileImageURL"
            createUserInDatabase(profileImageURL: defaultProfileImageURL)
            return
        }

        let storageRef = Storage.storage().reference().child("profile_images/\(UUID().uuidString).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }

                storageRef.downloadURL { url, error in
                    if let downloadURL = url?.absoluteString {
                        createUserInDatabase(profileImageURL: downloadURL)
                    }
                }
            }
        }
    }

    private func createUserInDatabase(profileImageURL: String) {
        firebaseService.signUp(email: email, password: password, userName: userName, userBio: userBio, userRole: selectedRole, userProfileImage: profileImageURL) { success, error in
            isLoading = false
            if success {
                successMessage = "Account created successfully!"
                clearFields()
            } else {
                errorMessage = error?.localizedDescription ?? "Error"
            }
        }
    }

    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        userName = ""
        userBio = ""
        selectedImage = nil
    }
}






