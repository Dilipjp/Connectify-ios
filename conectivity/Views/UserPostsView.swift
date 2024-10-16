//
//  UserPostsView.swift
//  conectivity
//
//  Created by Dilip on 2024-10-16.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

struct UserPostsView: View {
    @State private var userPosts: [Post] = []
    @State private var isLoading = true
    private var dbRef = Database.database().reference()

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading posts...")
            } else if userPosts.isEmpty {
                Text("No posts available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(userPosts, id: \.postId) { post in
                        VStack(alignment: .leading) {
                            Text(post.caption)
                                .font(.headline)
                            if let url = URL(string: post.postImageUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 300)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            VStack {
                                Button(action: {
                                    // Handle edit action
//                                    editPost(post: post)
                                }) {
                                    Text("Edit")
                                }
                                Button(action: {
                                    // Handle delete action
//                                    deletePost(postId: post.postId)
                                }) {
                                    Text("Delete")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            fetchUserPosts()
        }
    }

    // Fetch posts belonging to the current user

    func fetchUserPosts() {
        guard let user = Auth.auth().currentUser else { return }

        dbRef.child("posts")
            .queryOrdered(byChild: "userId")
            .queryEqual(toValue: user.uid)
            .observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
                var fetchedPosts: [Post] = []

                if snapshot.exists() && snapshot.hasChildren() {
                    for child in snapshot.children {
                        if let snap = child as? DataSnapshot,
                           let value = snap.value as? [String: Any] {
                            let postId = snap.key
                            let caption = value["caption"] as? String ?? ""
                            let postImageUrl = value["postImageUrl"] as? String ?? ""
                            
                            let post = Post(
                                postId: postId,
                                userId: user.uid,
                                postImageUrl: postImageUrl,
                                caption: caption,
                                likeCount: 0, // Default value
                                commentCount: 0, // Default value
                                timestamp: Date().timeIntervalSince1970, // Use current time
                                likedByCurrentUser: false, // Default value
                                isLikeButtonDisabled: false, // Default value
                                userData: nil, // Pass actual user data if available
                                comments: [] // Default to empty array
                            )
                            fetchedPosts.append(post)
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.userPosts = fetchedPosts
                    self.isLoading = false
                }
            }
    }






    // Delete post
    func deletePost(postId: String) {
        dbRef.child("posts").child(postId).removeValue { error, _ in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
            } else {
                fetchUserPosts() // Refresh the posts after deletion
            }
        }
    }

    // Edit post (implementation can vary based on your requirements)
    func editPost(post: Post) {
        // Navigate to an edit screen or open an edit modal
        
        print("Editing post: \(post.postId)")
    }
}



