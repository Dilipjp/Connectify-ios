//
//  HomeTab.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//
import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth

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
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))  // Optional: Add a border to the circle
                                        .padding(5)

                                    // Username
                                    Text(userData.userName)
                                        .font(.headline)
                                        .padding(.leading, 8)

                                    Spacer()
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

                            // Like, Comment, Share Icons with Count
                            HStack {
                                Button(action: {
                                        toggleLike(for: posts[index], at: index)
                                    }) {
                                        HStack {
                                            Image(systemName: posts[index].likedByCurrentUser ? "heart.fill" : "heart")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(posts[index].likedByCurrentUser ? .red : .gray)

                                            Text("\(posts[index].likeCount)")
                                                .font(.subheadline)
                                                .padding(.leading, 4)
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .disabled(posts[index].isLikeButtonDisabled)
                                .padding(.leading, 10)

                                Button(action: {
                                    // Comment action
                                }) {
                                    HStack {
                                        Image(systemName: "message")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.black)
                                        // Comment Count
                                        Text("\(posts[index].commentCount)")
                                            .font(.subheadline)
                                            .padding(.leading, 4)
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(.leading, 10)
                                
                                Button(action: {
                                    // Share action
                                }) {
                                    Image(systemName: "paperplane")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.black)
                                }
                                .padding(.leading, 10)
                                
                            }
                            .padding(.top, 5)
                            .padding(.bottom, 10)

                            // Post Caption
                            Text(posts[index].caption)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Connectify")
        }
        .onAppear {
            fetchPosts()  // Fetch posts when the view appears
        }
    }

    // Fetch posts from Firebase Realtime Database
    func fetchPosts() {
        let currentUserId = Auth.auth().currentUser?.uid  // Get the current user's ID

        dbRef.child("posts").observe(.value) { snapshot in
            var newPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let postId = dict["postId"] as? String,
                   let userId = dict["userId"] as? String,
                   let postImageUrl = dict["postImageUrl"] as? String,
                   let caption = dict["caption"] as? String,
                   let timestamp = dict["timestamp"] as? Double {

                    // Handle missing values for likeCount, commentCount, and likes
                    let likeCount = dict["likeCount"] as? Int ?? 0
                    let commentCount = dict["commentCount"] as? Int ?? 0

                    // Check if the current user has liked this post
                    let likesDict = dict["likes"] as? [String: Bool] ?? [:]
                    let likedByCurrentUser = likesDict[currentUserId!] ?? false

                    // Create the post object
                    let post = Post(postId: postId, userId: userId, postImageUrl: postImageUrl, caption: caption, likeCount: likeCount, commentCount: commentCount, timestamp: timestamp, likedByCurrentUser: likedByCurrentUser)
                    
                    // Append to the newPosts array
                    newPosts.append(post)
                }
            }

            // Sort posts by timestamp in descending order (latest first)
            self.posts = newPosts.sorted(by: { $0.timestamp > $1.timestamp })

            // Fetch user details for the posts
            fetchUserDetails(for: self.posts)
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
    
    func toggleLike(for post: Post, at index: Int) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let postRef = dbRef.child("posts").child(post.postId)

        // Disable the like button to prevent multiple taps
        self.posts[index].isLikeButtonDisabled = true

        // Optimistically update the UI for instant feedback
        var updatedPost = self.posts[index]
        updatedPost.likedByCurrentUser.toggle()  // Toggle like/unlike state
        updatedPost.likeCount += updatedPost.likedByCurrentUser ? 1 : -1  // Update like count
        self.posts[index] = updatedPost  // SwiftUI will automatically refresh the UI

        // Perform Firebase transaction
        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
            if var post = currentData.value as? [String: AnyObject] {
                var likes = post["likes"] as? [String: Bool] ?? [:]
                var likeCount = post["likeCount"] as? Int ?? 0

                if likes[currentUserId] != nil {
                    // User is unliking the post
                    likes[currentUserId] = nil
                    likeCount = max(likeCount - 1, 0)  // Ensure the count doesn't go below zero
                } else {
                    // User is liking the post
                    likes[currentUserId] = true
                    likeCount += 1
                }

                post["likes"] = likes as AnyObject
                post["likeCount"] = likeCount as AnyObject
                currentData.value = post

                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { error, committed, snapshot in
            DispatchQueue.main.async {
                // Re-enable the like button after Firebase responds
                self.posts[index].isLikeButtonDisabled = false

                if let error = error {
                    print("Error updating like: \(error.localizedDescription)")

                    // Revert the optimistic UI update in case of error
                    var revertedPost = self.posts[index]
                    revertedPost.likedByCurrentUser.toggle()  // Revert like/unlike state
                    revertedPost.likeCount += revertedPost.likedByCurrentUser ? 1 : -1  // Revert like count
                    self.posts[index] = revertedPost
                }
            }
        }
    

    }




}

// Post model

struct Post: Identifiable {
    let id = UUID()
    let postId: String
    let userId: String
    let postImageUrl: String
    let caption: String
    var likeCount: Int
    let commentCount: Int
    let timestamp: TimeInterval
    var likedByCurrentUser: Bool = false  // Track if the current user has liked the post
    var isLikeButtonDisabled: Bool = false
    var userData: UserData?  // Optional to store user data
}


// User data model
struct UserData {
    let userName: String
    let profileImage: UIImage
}








