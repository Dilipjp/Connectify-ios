//
//  PostTab.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//
import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

struct PostScreen: View {
    @State private var caption: String = ""
    @State private var postImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var successMessage: String? = nil
    var postId: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Create a Post")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            if let postImage = postImage {
                Image(uiImage: postImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .onTapGesture {
                        isImagePickerPresented = true
                    }
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 200)
                    .overlay(Text("Tap to select image").foregroundColor(.white))
                    .onTapGesture {
                        isImagePickerPresented = true
                    }
            }

            TextField("Caption", text: $caption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                savePost()
            }) {
                Text("Post")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $postImage)
            }

            // Loading Indicator
            if isLoading {
                ProgressView("Creating post...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }

            // Success Message
            if let successMessage = successMessage {
                Text(successMessage)
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
            
        
            

            Spacer()
        }
        .padding()
    }

    func savePost() {
        guard let user = Auth.auth().currentUser,
              let image = postImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        // Create a unique post ID
        let postId = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)

        let storageRef = Storage.storage().reference().child("post_images/\(postId).jpg")

        // Show loading indicator
        isLoading = true

        // Upload image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                isLoading = false
                return
            }

            // Get the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                if let url = url {
                    // Create post data
                    let postData: [String: Any] = [
                        "caption": caption,
                        "postId": postId,
                        "postImageUrl": url.absoluteString,
                        "timestamp": timestamp,
                        "userId": user.uid
                    ]

                    // Save post data to Realtime Database
                    let dbRef = Database.database().reference().child("posts").child(postId)
                    dbRef.setValue(postData) { error, _ in
                        // Hide loading indicator
                        isLoading = false

                        if let error = error {
                            print("Error saving post: \(error.localizedDescription)")
                        } else {
                            // Clear fields after posting
                            caption = ""
                            postImage = nil

                            // Show success message
                            successMessage = "Post created successfully!"
                            // Remove success message after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                successMessage = nil
                            }
                        }
                    }
                }
            }
        }
    }
}





