//
//  HomeScreen.swift
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
        dbRef.child("posts").observeSingleEvent(of: .value) { snapshot in
            var newPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let postId = snapshot.key as? String,
                   let userId = dict["userId"] as? String,
                   let postImageUrl = dict["postImageUrl"] as? String,
                   let caption = dict["caption"] as? String {
                    
                    var comments: [Comment] = []

                    // Fetch comments from the nested structure
                    if let commentsDict = dict["comments"] as? [String: Any] {
                        for (commentId, commentData) in commentsDict {
                            if let commentDict = commentData as? [String: Any],
                               let userId = commentDict["userId"] as? String,
                               let username = commentDict["username"] as? String,
                               let text = commentDict["text"] as? String,
                               let timestamp = commentDict["timestamp"] as? TimeInterval {
                                let comment = Comment(id: commentId, postId: postId, userId: userId, username: username, text: text, timestamp: timestamp)
                                comments.append(comment)
                            }
                        }
                    }

                    let post = Post(postId: postId, userId: userId, postImageUrl: postImageUrl, caption: caption, comments: comments)
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
                        }
                    }.resume()
                }
            }
        }
    }
}
