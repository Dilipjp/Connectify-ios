import SwiftUI
import Firebase
import FirebaseDatabase

struct HomeScreen: View {
    @State private var posts: [Post] = []

    // Reference to the Firebase Realtime Database
    private var dbRef = Database.database().reference()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(posts.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 10) {
                            // User Profile Image and Name in a Horizontal Stack (HStack)
                            if let userData = posts[index].userData {
                                HStack(alignment: .center) {
                                    // Profile Image
                                    Image(uiImage: userData.profileImage)
                                        .resizable()
                                        .scaledToFill()  // Ensures the image fills the frame and is cropped
                                        .frame(width: 40, height: 40)  // Ensure square frame
                                        .clipShape(Circle())  // Clips the image into a perfect circle
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))  // Optional: Add a border to the circle
                                        .padding(5) // Round profile image

                                    // Username
                                    Text(userData.userName)
                                        .font(.headline)
                                        .padding(.leading, 8) // Space between image and name
                                    
                                    Spacer()  // Pushes content to the left, if needed for alignment
                                }
                                .padding(.horizontal, 10)
                                .padding(.top, 5)
                            }

                            // Post Image
                            AsyncImage(url: URL(string: posts[index].postImageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)

                            // Post Caption
                            Text(posts[index].caption)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)

                            // Like Button and Count
                            HStack {
                                Button(action: {
                                    toggleLike(for: index)
                                }) {
                                    Image(systemName: posts[index].isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(posts[index].isLiked ? .red : .gray)
                                        .padding(.leading, 10)
                                }
                                
                                Text("\(posts[index].likeCount) likes")
                                    .padding(.leading, 5)

                                Spacer()
                            }
                            .padding(.bottom, 10)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Home")
        }
        .onAppear {
            fetchPosts()  // Fetch posts when the view appears
        }
    }

    // Fetch posts from Firebase Realtime Database
    func fetchPosts() {
        dbRef.child("posts").observe(.value) { snapshot in
            var newPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let postId = dict["postId"] as? String,
                   let userId = dict["userId"] as? String,
                   let postImageUrl = dict["postImageUrl"] as? String,
                   let caption = dict["caption"] as? String,
                   let likeCount = dict["likeCount"] as? Int,
                   let isLiked = dict["isLiked"] as? Bool {
                    let post = Post(postId: postId, userId: userId, postImageUrl: postImageUrl, caption: caption, likeCount: likeCount, isLiked: isLiked)
                    newPosts.append(post)
                }
            }
            self.posts = newPosts
            fetchUserDetails(for: newPosts)
        }
    }

    // Fetch user details for each post from Firebase
    func fetchUserDetails(for posts: [Post]) {
        for (index, post) in posts.enumerated() {
            dbRef.child("users").child(post.userId).observeSingleEvent(of: .value) { snapshot in
                if let userDict = snapshot.value as? [String: Any],
                   let userName = userDict["userName"] as? String,
                   let userProfileImage = userDict["userProfileImage"] as? String,
                   let imageUrl = URL(string: userProfileImage) {
                    
                    // Load the profile image asynchronously
                    URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                // Update the specific post with user data
                                self.posts[index].userData = UserData(userName: userName, profileImage: image)
                            }
                        }
                    }.resume()
                }
            }
        }
    }

    // Toggle like status for a specific post
    func toggleLike(for index: Int) {
        guard index < posts.count else { return }
        
        // Update the like status in Firebase
        let post = posts[index]
        let updatedLikeCount = post.isLiked ? post.likeCount - 1 : post.likeCount + 1
        let isLiked = !post.isLiked

        dbRef.child("posts").child(post.postId).updateChildValues([
            "likeCount": updatedLikeCount,
            "isLiked": isLiked
        ]) { error, _ in
            if error == nil {
                // Update the local state of posts
                DispatchQueue.main.async {
                    self.posts[index].likeCount = updatedLikeCount
                    self.posts[index].isLiked = isLiked
                }
            }
        }
    }
}
