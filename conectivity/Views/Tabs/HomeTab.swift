//
//  HomeTab.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//
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
                            
                            // Comments Section
                            ForEach(posts[index].comments, id: \.id) { comment in
                                VStack(alignment: .leading) {
                                    Text(comment.username).fontWeight(.bold)
                                    Text(comment.text)
                                        .font(.subheadline)
                                    Text("Just now") // You might want to format the timestamp
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 10)
                                .padding(.bottom, 5)
                            }
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
                   let caption = dict["caption"] as? String {
                    let post = Post(postId: postId, userId: userId, postImageUrl: postImageUrl, caption: caption, comments: []) // Initialize with an empty comments array
                    newPosts.append(post)
                }
            }
            self.posts = newPosts
            fetchUserDetails(for: newPosts)

            // After fetching posts, fetch comments for each post
            for post in newPosts {
                fetchComments(for: post.postId) { comments in
                    if let index = newPosts.firstIndex(where: { $0.postId == post.postId }) {
                        newPosts[index].comments = comments // Update the comments for the post
                    }
                }
            }
        }
    }

    // Fetch comments for a specific post
    func fetchComments(for postId: String, completion: @escaping ([Comment]) -> Void) {
        dbRef.child("comments").child(postId).observe(.value) { snapshot in
            var comments: [Comment] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let userId = dict["userId"] as? String,
                   let username = dict["username"] as? String,
                   let text = dict["text"] as? String,
                   let timestamp = dict["timestamp"] as? TimeInterval {
                    let comment = Comment(id: snapshot.key, postId: postId, userId: userId, username: username, text: text, timestamp: timestamp)
                    comments.append(comment)
                }
            }
            completion(comments) // Pass comments back to the caller
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
}

