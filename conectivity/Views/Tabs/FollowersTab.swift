//
//  ProfileTab.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

struct FollowersScreen: View {
    @State private var allUsers: [User] = []
    @State private var currentUserId: String = ""
    @State private var followers: [String: Bool] = [:]

    var body: some View {
        List(allUsers) { user in
            if user.userId != currentUserId { 
                HStack {
                    // Display profile image
                    AsyncImage(url: URL(string: user.userProfileImage)) { image in
                        image
                            .resizable() // Allow image to be resized
                            .scaledToFit() // Maintain aspect ratio
                            .frame(width: 40, height: 40) // Fixed width and height
                            .clipShape(Circle()) // Make it circular
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1)) // Optional: add border
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1)) // Optional: add border
                    }

                    Text(user.userName)
                        .font(.headline)

                    Spacer()

                    // Show Follow/Unfollow button based on followers list
                    if followers[user.userId] == true {
                        Button("Unfollow") {
                            unfollowUser(userId: user.userId)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Follow") {
                            followUser(userId: user.userId)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .onAppear {
            fetchCurrentUserId() 
            loadAllUsers()
        }
    }
    // Fetch current user ID from Firebase Auth
        private func fetchCurrentUserId() {
            if let user = Auth.auth().currentUser {
                currentUserId = user.uid
            }
        }

    // Fetch all users and followers
    func loadAllUsers() {
        let dbRef = Database.database().reference()

        // Fetch all users
        dbRef.child("users").observeSingleEvent(of: .value) { snapshot in
            if let usersData = snapshot.value as? [String: Any] {
                var tempUsers: [User] = []
                for (key, value) in usersData {
                    if let userData = value as? [String: Any],
                       let userName = userData["userName"] as? String,
                       let userProfileImage = userData["userProfileImage"] as? String {
                        let user = User(userId: key, userName: userName, userProfileImage: userProfileImage)
                        tempUsers.append(user)

                        // Check if the current user is following this user
                        if let followersData = userData["followers"] as? [String: Bool] {
                            followers[key] = followersData[currentUserId] != nil
                        }
                    }
                }
                self.allUsers = tempUsers
            }
        }
    }

    // Follow a user
    func followUser(userId: String) {
        let dbRef = Database.database().reference()
        dbRef.child("users").child(userId).child("followers").child(currentUserId).setValue(true) { error, _ in
            if error == nil {
                followers[userId] = true
            }
        }
    }

    // Unfollow a user
    func unfollowUser(userId: String) {
        let dbRef = Database.database().reference()
        dbRef.child("users").child(userId).child("followers").child(currentUserId).removeValue { error, _ in
            if error == nil {
                followers[userId] = false
            }
        }
    }
}

struct User: Identifiable {
    var id: String { userId }
    var userId: String
    var userName: String
    var userProfileImage: String
}
