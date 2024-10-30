import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

struct ProfileScreen: View {
    @State private var profileImage: UIImage? = nil
    @State private var username: String = ""
    @State private var userBio: String = ""
    @State private var postCount: Int = 0
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var isImagePickerPresented = false
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var successMessage: String? = nil
    @State private var userRole: String = ""

    private var dbRef = Database.database().reference()

    var body: some View {
        NavigationView {
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
                            .overlay(Circle().stroke(Color.black, lineWidth: 4))
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
                    // Post, Followers, and Following counts in a row
                    HStack(spacing: 30) {
//                        VStack {
//                            Text("\(postCount)")
//                                .font(.headline)
//                            Text("Posts")
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                        }
                        NavigationLink(destination: UserPostsView()) {
                                VStack {
                                    Text("\(postCount)")
                                        .font(.headline)
                                    Text("Posts")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding() // Add padding for better tap area
                                .background(Color.clear) // Make the background clear to avoid visual issues
                            }
                        VStack {
                            Text("\(followersCount)")
                                .font(.headline)
                            Text("Followers")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text("\(followingCount)")
                                .font(.headline)
                            Text("Following")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
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
                            if userRole == "Moderator" {
                                NavigationLink(destination: AllPostsView()) {
                                    Text("All Posts")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            } else if userRole == "Admin" {
                                NavigationLink(destination: AllUsersView()) {
                                    Text("All Users")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                successMessage = nil
                            }
                            if userRole == "Moderator" {
                                    NavigationLink(destination: AllPostsView()) { // Link to AllPostsView
                                        Text("All Posts")
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                            .cornerRadius(10                                 )
                                                                        }
                                                                    }
                        })
                    }
                    
                    // Success message
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .foregroundColor(.black)
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
                    
                    Spacer()
//                    NavigationLink(destination: UserPostsView()) {
//                        Text("View My Posts")
//                            .font(.headline)
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .background(Color.black)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
                }
            }
            .padding()
            .onAppear {
                fetchUserProfile()
                fetchPostCount()
                fetchFollowersCount()
                fetchFollowingCount()
            }
        }
    }

    // Fetch user profile details from Firebase
    func fetchUserProfile() {
        guard let user = Auth.auth().currentUser else { return }

        // Fetch the user details (username and profile image) from the "users" node in Firebase Realtime Database
        dbRef.child("users").child(user.uid).observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                // Fetch the username
                if let fetchedUsername = value["userName"] as? String {
                    DispatchQueue.main.async {
                        self.username = fetchedUsername
                    }
                } else {
                    DispatchQueue.main.async {
                        self.username = "Your Awesome Name" // Fallback if no username is found
                    }
                }

                // Fetch the profile image URL
                if let profileImageUrlString = value["userProfileImage"] as? String,
                   let profileImageUrl = URL(string: profileImageUrlString) {
                    // Download the image asynchronously
                    URLSession.shared.dataTask(with: profileImageUrl) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.profileImage = image
                            }
                        }
                    }.resume()
                }

                // Fetch user bio if needed
                if let fetchedBio = value["userBio"] as? String {
                    DispatchQueue.main.async {
                        self.userBio = fetchedBio
                    }
                }
            } else {
                DispatchQueue.main.async {
                    // Handle case where user data is not found
                    self.username = "Your Awesome Name"
                    self.userBio = "No bio available"
                }
            }
        }
    }
    // Fetch post count for the current user from Firebase
        func fetchPostCount() {
            guard let user = Auth.auth().currentUser else { return }

            // Query to get the posts for the current user
            dbRef.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: user.uid).observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    let count = snapshot.childrenCount
                    DispatchQueue.main.async {
                        self.postCount = Int(count) // Update the post count
                    }
                } else {
                    DispatchQueue.main.async {
                        self.postCount = 0 // Set post count to 0 if no posts are found
                    }
                }
            }
        }
    // Fetch followers count for the current user
        func fetchFollowersCount() {
            guard let user = Auth.auth().currentUser else { return }

            // Fetch followers count from the "followers" node inside the current user's node
            dbRef.child("users").child(user.uid).child("followers").observeSingleEvent(of: .value) { snapshot in
                let count = snapshot.childrenCount
                DispatchQueue.main.async {
                    self.followersCount = Int(count)
                }
            }
        }

        // Fetch following count for the current user
        func fetchFollowingCount() {
            guard let user = Auth.auth().currentUser else { return }

            // Iterate over all users and check if the current user is in their followers list
            dbRef.child("users").observeSingleEvent(of: .value) { snapshot in
                var followingCount = 0
                for case let child as DataSnapshot in snapshot.children {
                    if let followers = child.childSnapshot(forPath: "followers").value as? [String: Any] {
                        if followers.keys.contains(user.uid) {
                            followingCount += 1
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.followingCount = followingCount
                }
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
