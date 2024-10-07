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
    @State private var newComments: [String: String] = [:] // Store new comments for each post
    
    // Reference to the Firebase Realtime Database
    private var dbRef = Database.database().reference()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 10) {
                            // User Profile Image and Name in a Horizontal Stack (HStack)
                            if let userData = post.userData {
                                HStack(alignment: .center) {
                                    // Profile Image
                                    Image(uiImage: userData.profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
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
                            AsyncImage(url: URL(string: post.postImageUrl)) { image in
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
                            Text(post.caption)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)
                            
                            // Comments Section
                            if post.comments.isEmpty {
                                Text("No comments yet.")
                                    .padding(.horizontal, 10)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(post.comments) { comment in
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

                            // Comment Input Section
                            commentInput(for: post)
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

    // Separate view for comment input
    private func commentInput(for post: Post) -> some View {
        HStack {
            TextField("Add a comment...", text: Binding(
                get: { newComments[post.id, default: ""] },
                set: { newComments[post.id] = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                addComment(for: post)
            }) {
                Text("Post")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    // Fetch posts from Firebase Realtime Database
    func fetchPosts() {
        dbRef.child("posts").observe(.value) { (snapshot: DataSnapshot) in
            var newPosts: [Post] = []

            // Ensure that snapshot is a valid DataSnapshot
            if let dict = snapshot.value as? [String: Any] {
                for (key, value) in dict {
                    if let postDict = value as? [String: Any],
                       let userId = postDict["userId"] as? String,
                       let postImageUrl = postDict["postImageUrl"] as? String,
                       let caption = postDict["caption"] as? String,
                       let timestamp = postDict["timestamp"] as? Int { // Fetch the timestamp
                        let postId = key // Use key as postId
                        let post = Post(id: postId, userId: userId, postImageUrl: postImageUrl, caption: caption, timestamp: timestamp) // Include timestamp
                        newPosts.append(post)
                    }
                }
            }

            self.posts = newPosts
            fetchUserDetails(for: newPosts)

            // After fetching posts, fetch comments for each post
            for post in newPosts {
                fetchComments(for: post.id) { comments in
                    if let index = newPosts.firstIndex(where: { $0.id == post.id }) {
                        newPosts[index].comments = comments // Update the comments for the post
                    }
                }
            }
        }
    }

    // Add comment to Firebase
    func addComment(for post: Post) {
        guard let user = Auth.auth().currentUser else { return }

        let commentId = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        let commentText = newComments[post.id, default: ""]

        let commentDict: [String: Any] = [
            "userId": user.uid,
            "username": user.displayName ?? "Anonymous",
            "text": commentText,
            "timestamp": timestamp
        ]

        dbRef.child("comments").child(post.id).child(commentId).setValue(commentDict) { error, _ in
            if let error = error {
                print("Error adding comment: \(error.localizedDescription)")
                return
            }

            // Clear the comment input after posting
            newComments[post.id] = ""
            fetchComments(for: post.id) { comments in
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index].comments = comments
                }
            }
        }
    }
    
    // Fetch comments for a specific post
    func fetchComments(for postId: String, completion: @escaping ([Comment]) -> Void) {
        dbRef.child("comments").child(postId).observeSingleEvent(of: .value) { snapshot in
            var comments: [Comment] = []
            
            // Check if the snapshot is valid
            if let dict = snapshot.value as? [String: Any] {
                for (key, value) in dict {
                    if let commentDict = value as? [String: Any],
                       let userId = commentDict["userId"] as? String,
                       let username = commentDict["username"] as? String,
                       let text = commentDict["text"] as? String,
                       let timestamp = commentDict["timestamp"] as? TimeInterval {
                        let comment = Comment(id: key, postId: postId, userId: userId, username: username, text: text, timestamp: timestamp)
                        comments.append(comment)
                    }
                }
            }
            
            completion(comments) // Pass the comments back to the caller
        }
    }

    // Fetch user details for each post from Firebase
    func fetchUserDetails(for posts: [Post]) {
        for (index, post) in posts.enumerated() {
            dbRef.child("users").child(post.userId).getData { error, snapshot in
                if let error = error {
                    print("Error fetching user data for userId \(post.userId): \(error.localizedDescription)")
                    return
                }
                
                guard let userDict = snapshot?.value as? [String: Any] else {
                    print("No user data available for userId: \(post.userId)")
                    return
                }

                if let userName = userDict["userName"] as? String,
                   let userProfileImage = userDict["userProfileImage"] as? String,
                   let imageUrl = URL(string: userProfileImage) {
                    
                    URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                if index < self.posts.count {
                                    self.posts[index].userData = UserData(userName: userName, profileImage: image)
                                }
                            }
                        } else {
                            print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }.resume()
                }
            }
        }
    }
}
