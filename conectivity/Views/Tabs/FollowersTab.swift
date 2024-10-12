//
//  FollowersTab.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

struct FollowersScreen: View {
    @State private var followers: [Follower] = []  // Array to hold follower data
    private var dbRef = Database.database().reference()
    
    var body: some View {
        VStack {
            if followers.isEmpty {
                Text("No Followers")
                    .font(.headline)
                    .padding()
            } else {
                List(followers) { follower in
                    HStack {
                        if let imageUrl = follower.profileImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                     .scaledToFill()
                                     .frame(width: 40, height: 40)
                                     .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 40, height: 40)
                            }
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 40, height: 40)
                        }
                        Text(follower.username)
                            .font(.headline)
                            .padding(.leading, 10)
                    }
                }
                .listStyle(PlainListStyle()) // Optional styling
            }
        }
        .onAppear {
            fetchFollowers()
        }
        .navigationTitle("Followers")
    }
    
    // Function to fetch followers from Firebase
    func fetchFollowers() {
        guard let user = Auth.auth().currentUser else { return }
        
        dbRef.child("followers").child(user.uid).observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                var loadedFollowers: [Follower] = []
                
                for (_, followerData) in value {
                    if let followerInfo = followerData as? [String: Any],
                       let username = followerInfo["username"] as? String,
                       let profileImageUrl = followerInfo["profileImageUrl"] as? String {
                        let follower = Follower(id: UUID().uuidString, username: username, profileImageUrl: profileImageUrl)
                        loadedFollowers.append(follower)
                    }
                }
                followers = loadedFollowers
            }
        }
    }
}

// Data model for a Follower
struct Follower: Identifiable {
    var id: String
    var username: String
    var profileImageUrl: String?
}

struct FollowersScreen_Previews: PreviewProvider {
    static var previews: some View {
        FollowersScreen()
    }
}


