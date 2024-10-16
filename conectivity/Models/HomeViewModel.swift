//
//  HomeViewModel.swift
//  conectivity
//
//  Created by Dilip on 2024-10-07.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth

class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var userDataCache: [String: UserData] = [:]
    
    private var dbRef = Database.database().reference()

    // Fetch posts from Firebase Realtime Database
    func fetchPosts() {
        let currentUserId = Auth.auth().currentUser?.uid  // Get the current user's ID

        dbRef.child("posts").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            var newPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let postId = dict["postId"] as? String,
                   let userId = dict["userId"] as? String,
                   let postImageUrl = dict["postImageUrl"] as? String,
                   let caption = dict["caption"] as? String,
                   let timestamp = dict["timestamp"] as? Double {

                    // Handle missing values for likeCount and commentCount
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
            self.fetchUserDetails(for: self.posts)
        }
    }

    // Fetch user details for each post from Firebase
    func fetchUserDetails(for posts: [Post]) {
        for (index, post) in posts.enumerated() {
            // Check if user data is already cached
            if let cachedUserData = userDataCache[post.userId] {
                self.posts[index].userData = cachedUserData
            } else {
                // Fetch user details if not cached
                dbRef.child("users").child(post.userId).observeSingleEvent(of: .value) { [weak self] snapshot in
                    guard let self = self else { return }

                    if let userDict = snapshot.value as? [String: Any],
                       let userName = userDict["userName"] as? String,
                       let userProfileImage = userDict["userProfileImage"] as? String,
                       let imageUrl = URL(string: userProfileImage) {
                        
                        // Load the profile image asynchronously
                        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    // Create user data
                                    let userData = UserData(userName: userName, profileImage: image)

                                    // Update the user data cache
                                    self.userDataCache[post.userId] = userData

                                    // Update the specific post with user data
                                    self.posts[index].userData = userData
                                }
                            }
                        }.resume()
                    }
                }
            }
        }
    }
}

