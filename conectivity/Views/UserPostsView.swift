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
    @State private var selectedPost: Post? = nil // For navigation
    @State private var showEditPostView = false // To trigger sheet for editing post
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
                        VStack(alignment: .leading, spacing: 15) {
                            // Post Caption
                            Text(post.caption)
                                .font(.headline)
                            
                            // Display Post Image
                            if let url = URL(string: post.postImageUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 250) // Limit image height
                                        .cornerRadius(8)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            
                            // HStack for Edit and Delete buttons
                            HStack {
                                Button(action: {
                                    selectedPost = post
                                    showEditPostView = true
                                }) {
                                    Text("Edit")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // Prevents triggering unwanted effects
                                
                                Spacer()

                                Button(action: {
                                    deletePost(postId: post.postId)
                                }) {
                                    Text("Delete")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // Prevents triggering unwanted effects
                            }
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 8) // Padding between posts
                    }
                }
            }
        }
        .onAppear {
            fetchUserPosts()
        }
        .sheet(isPresented: $showEditPostView) {
            if let selectedPost = selectedPost {
                EditPostView(post: .constant(selectedPost)) // Pass a binding to EditPostView
            }
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
                            let locationName = value["locationName"] as? String ?? ""

                            let post = Post(
                                postId: postId,
                                userId: user.uid,
                                postImageUrl: postImageUrl,
                                locationName: locationName,
                                caption: caption,
                                likeCount: 0,
                                commentCount: 0,
                                timestamp: Date().timeIntervalSince1970,
                                likedByCurrentUser: false,
                                isLikeButtonDisabled: false,
                                userData: nil,
                                comments: []
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
        print("Error deleting post:")
        dbRef.child("posts").child(postId).removeValue { error, _ in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
            } else {
                fetchUserPosts() // Refresh the posts after deletion
            }
        }
    }
}




