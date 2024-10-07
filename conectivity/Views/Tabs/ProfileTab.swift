//
//  ProfileTab.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

struct ProfileScreen: View {
    @State private var profileImage: UIImage? = nil
    @State private var username: String = ""
    @State private var userBio: String = ""
    @State private var isImagePickerPresented = false
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var successMessage: String? = nil
    @State private var userPosts: [Post] = [] // State variable to hold user posts

    private var dbRef = Database.database().reference()

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Updating...")
            } else {
                // Profile image (tappable)
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                        .shadow(radius: 10)
                        .padding()
                        .onTapGesture {
                            isImagePickerPresented = true
                        }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 150, height: 150)
                        .overlay(Text("Tap to Edit").foregroundColor(.white))
                        .onTapGesture {
                            isImagePickerPresented = true
                        }
                }

                // Username
                Text(username.isEmpty ? "No username" : username)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)

                // Bio
                Text(userBio.isEmpty ? "No bio available" : userBio)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Edit Profile Button
                Button(action: {
                    isEditing.toggle() // This will trigger the sheet to show
                }) {
                    Text("Edit Profile")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(image: $profileImage)
                }
                .sheet(isPresented: $isEditing) {
                    EditProfileView(username: $username, userBio: $userBio, profileImage: $profileImage, saveAction: saveProfileData, onSuccess: { message in
                        successMessage = message
                        // Remove success message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            successMessage = nil
                        }
                    })
                }

                // Success message
                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }

                // Log Out Button
                Button(action: logOut) {
                    Text("Log Out")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // User's Posts Section
                Text("Your Posts")
                    .font(.title)
                    .fontWeight(.bold)

                // Display user posts in a grid
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 10) {
                    ForEach(userPosts) { post in
                        if let url = URL(string: post.postImageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
                .padding()

                Spacer()
            }
        }
        .padding()
        .onAppear {
            fetchUserProfile()
            fetchUserPosts() // Fetch user posts when the view appears
        }
    }

    // Fetch user profile details from Firebase
    func fetchUserProfile() {
        guard let user = Auth.auth().currentUser else { return }

        // Fetch the username and profile image from Firebase Authentication
        username = user.displayName ?? "Your Awesome Name"

        if let photoURL = user.photoURL {
            URLSession.shared.dataTask(with: photoURL) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        profileImage = image
                    }
                }
            }.resume()
        }

        // Fetch user bio from Firebase Realtime Database
        dbRef.child("users").child(user.uid).observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Any],
               let bio = value["userBio"] as? String {
                userBio = bio
            }
        }
    }

    // Fetch user posts from Firebase
    func fetchUserPosts() {
        guard let user = Auth.auth().currentUser else { return }

        dbRef.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: user.uid).observeSingleEvent(of: .value) { snapshot in
            var posts: [Post] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let postDict = childSnapshot.value as? [String: Any],
                   let postImageUrl = postDict["postImageUrl"] as? String,
                   let caption = postDict["caption"] as? String,
                   let timestamp = postDict["timestamp"] as? Int {
                    
                    let post = Post(id: childSnapshot.key, userId: user.uid, postImageUrl: postImageUrl, caption: caption, timestamp: timestamp)
                    posts.append(post)
                }
            }
            self.userPosts = posts // Update the state with fetched posts
        }
    }
    
    // Log out the user
    func logOut() {
        do {
            try Auth.auth().signOut()
            // Redirect to sign-in page
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }

    // Save updated profile data to Firebase
    func saveProfileData() {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true // Start loading

        // Update username
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = username
        changeRequest.commitChanges { error in
            if let error = error {
                print("Error updating username: \(error.localizedDescription)")
                self.isLoading = false // Stop loading
                return
            }
        }

        // Update profile image
        if let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference().child("profile_images/\(user.uid).jpg")
            
            // Upload the image to Firebase Storage
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    self.isLoading = false // Stop loading
                    return
                } else {
                    // Get the download URL
                    storageRef.downloadURL { url, error in
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                            self.isLoading = false // Stop loading
                            return
                        } else if let url = url {
                            // Update user's photo URL in Firebase Authentication
                            let changeRequest = user.createProfileChangeRequest()
                            changeRequest.photoURL = url
                            changeRequest.commitChanges { error in
                                if let error = error {
                                    print("Error updating profile image: \(error.localizedDescription)")
                                    self.isLoading = false // Stop loading
                                    return
                                } else {
                                    // Save the profile image URL to Realtime Database
                                    let userInfo = ["userName": username, "userBio": userBio, "userProfileImage": url.absoluteString]
                                    dbRef.child("users").child(user.uid).updateChildValues(userInfo) { error, _ in
                                        if let error = error {
                                            print("Error saving user profile image URL: \(error.localizedDescription)")
                                            self.isLoading = false // Stop loading
                                            return
                                        } else {
                                            // Fetch the updated profile data (optional)
                                            fetchUserProfile()
                                            self.isLoading = false // Stop loading
                                            // Success message
                                            successMessage = "Profile updated successfully!"
                                            // Remove success message after 3 seconds
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                successMessage = nil
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // Save user bio in Firebase Realtime Database if no image is uploaded
            let userInfo = ["userName": username, "userBio": userBio]
            dbRef.child("users").child(user.uid).updateChildValues(userInfo) { error, _ in
                if let error = error {
                    print("Error saving user bio: \(error.localizedDescription)")
                    self.isLoading = false // Stop loading
                    return
                } else {
                    // Fetch the updated profile data
                    fetchUserProfile()
                    self.isLoading = false // Stop loading
                    // Success message
                    successMessage = "Profile updated successfully!"
                    // Remove success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        successMessage = nil
                    }
                }
            }
        }
    }
}







