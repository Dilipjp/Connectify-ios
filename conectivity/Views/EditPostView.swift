//
//  EditPostView.swift
//  conectivity
//
//  Created by Dilip on 2024-10-16.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

struct EditPostView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var post: Post
    @State private var newCaption: String = ""
    @State private var newPostImage: UIImage? // State for new image
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Post")
                .font(.largeTitle)
                .padding()

            // Display current post image
            if !post.postImageUrl.isEmpty, let url = URL(string: post.postImageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                         .scaledToFit()
                         .frame(height: 200)
                         .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
            } else {
                // Handle the case where postImageUrl is empty or invalid
                Text("No image available")
                    .foregroundColor(.gray)
            }

            // Button to select a new image
            Button(action: {
                selectImage() // Action to present image picker
            }) {
                Text("Select New Image")
                    .foregroundColor(.blue)
            }

            // Caption text field
            TextField("Caption", text: $newCaption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Update Post button
            Button(action: {
                updatePost()
            }) {
                Text("Update Post")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            newCaption = post.caption // Load the current caption
        }
        .padding()
        .sheet(isPresented: $isLoading) {
            ImagePicker(image: $newPostImage) // Present image picker
        }
    }

    // Function to update the post in the database
    private func updatePost() {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }
        
        // Check if there's a new image to upload
        if let image = newPostImage {
            uploadImageAndSavePost(image: image, userId: user.uid)
        } else {
            // If no new image, just update the caption
            let dbRef = Database.database().reference().child("posts").child(post.postId)
            dbRef.updateChildValues(["caption": newCaption]) { error, _ in
                if let error = error {
                    print("Error updating post: \(error.localizedDescription)")
                } else {
                    print("Post updated successfully!")
                    presentationMode.wrappedValue.dismiss() // Dismiss the view after updating
                }
            }
        }
    }

    private func uploadImageAndSavePost(image: UIImage, userId: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        // Use the existing post ID to update the post image
        let storageRef = Storage.storage().reference().child("post_images/\(post.postId).jpg")

        isLoading = true // Show loading indicator

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
                    // Update post data with new caption and image URL
                    let postData: [String: Any] = [
                        "caption": newCaption,
                        "postImageUrl": url.absoluteString,
                    ]

                    // Save updated post data to Realtime Database
                    let dbRef = Database.database().reference().child("posts").child(post.postId)
                    dbRef.updateChildValues(postData) { error, _ in
                        isLoading = false

                        if let error = error {
                            print("Error updating post: \(error.localizedDescription)")
                        } else {
                            print("Post updated successfully!")
                            presentationMode.wrappedValue.dismiss() // Dismiss the view after updating
                        }
                    }
                }
            }
        }
    }
    
    private func selectImage() {
        // Implement your image selection logic (using UIImagePickerController)
        // This would typically involve showing the image picker to allow users to choose an image
        // Since `isLoading` is used for the image picker, set it to true to show the picker.
        isLoading = true
    }
}
