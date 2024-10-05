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
    var userId: String
    var username: String

    @EnvironmentObject var firebaseService: FirebaseService

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

            // Loading Indicator for post creation
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
    }

    private func savePost() {
        guard let user = Auth.auth().currentUser,
              let image = postImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        let postId = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)

        let storageRef = Storage.storage().reference().child("post_images/\(postId).jpg")

        isLoading = true // Show loading indicator

        // Upload image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                isLoading = false // Hide loading indicator
                return
            }

            // Get the download URL
            storageRef.downloadURL { url, error in
                guard let imageUrl = url?.absoluteString else {
                    print("Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
                    isLoading = false // Hide loading indicator
                    return
                }

                // Create a post object
                let postDict: [String: Any] = [
                    "userId": user.uid,
                    "postImageUrl": imageUrl,
                    "caption": caption,
                    "timestamp": timestamp
                ]

                // Save post to Firebase Realtime Database
                let postRef = Database.database().reference().child("posts").child(postId)
                postRef.setValue(postDict) { error, _ in
                    isLoading = false // Hide loading indicator
                    if let error = error {
                        print("Error saving post: \(error.localizedDescription)")
                    } else {
                        self.successMessage = "Post created successfully!"
                        self.caption = "" // Clear caption
                        self.postImage = nil // Clear image
                    }
                }
            }
        }
    }
}
