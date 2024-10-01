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
                                    // Like action
                                }) {
                                    HStack {
                                        Image(systemName: "heart")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.black)
                                        // Like Count
                                        Text("\(posts[index].likeCount)")
                                            .font(.subheadline)
                                            .padding(.leading, 4)
                                            .foregroundColor(.black)
                                    }
                                }
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
        dbRef.child("posts").observe(.value) { snapshot in
            var newPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let postId = dict["postId"] as? String,
                   let userId = dict["userId"] as? String,
                   let postImageUrl = dict["postImageUrl"] as? String,
                   let caption = dict["caption"] as? String,
                   let likeCount = dict["likeCount"] as? Int,    // Fetch like count
                   let commentCount = dict["commentCount"] as? Int { // Fetch comment count
                    let post = Post(postId: postId, userId: userId, postImageUrl: postImageUrl, caption: caption, likeCount: likeCount, commentCount: commentCount)
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
}

// Post model
struct Post: Identifiable {
    let id = UUID()
    let postId: String
    let userId: String
    let postImageUrl: String
    let caption: String
    let likeCount: Int
    let commentCount: Int
    var userData: UserData?  // Optional to store user data
}

// User data model
struct UserData {
    let userName: String
    let profileImage: UIImage
}







