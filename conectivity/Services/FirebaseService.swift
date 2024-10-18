import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class FirebaseService: ObservableObject {
    @Published private(set) var isLoggedIn: Bool = false
    private var dbRef = Database.database().reference()
    @Published var isLoading: Bool = false // Added isLoading to show loading status
    
    init() {
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async {
                self.isLoggedIn = user != nil
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let _ = result {
                    self?.isLoggedIn = true
                    completion(true, nil)
                } else if let error = error {
                    self?.isLoggedIn = false
                    print("Sign-in error: \(error.localizedDescription)")
                    completion(false, error)
                }
            }
        }
    }
    
    // Sign up with additional user information
    func signUp(email: String, password: String, userName: String, userBio: String, userRole: String, userProfileImage: String?, completion: @escaping (Bool, Error?) -> Void) {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let user = result?.user {
                    let userData: [String: Any] = [
                        "userEmail": email,
                        "userName": userName,
                        "userBio": userBio,
                        "userProfileImage": userProfileImage ?? "defaultProfileImageURL",
                        "userRole": userRole.isEmpty ? "user" : userRole,
                        "userStatus": "active",
                        "userCreatedAt": [".sv": "timestamp"] // Use server timestamp
                    ]
                    
                    self?.dbRef.child("users").child(user.uid).setValue(userData) { error, _ in
                        if let error = error {
                            print("Error saving user data: \(error.localizedDescription)")
                        }
                        completion(error == nil, error)
                    }
                } else if let error = error {
                    print("Sign-up error: \(error.localizedDescription)")
                    completion(false, error)
                }
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Bool, Error?) -> Void) {
        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Password reset error: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    // Fetch user data once
    func fetchUserData(completion: @escaping (DataSnapshot?) -> Void) {
        dbRef.child("users").observeSingleEvent(of: .value) { snapshot in
            completion(snapshot)
        }
    }
    
    func updateLoginStatus() {
        DispatchQueue.main.async {
            self.isLoggedIn = Auth.auth().currentUser != nil
        }
    }
    
    // Fetch user data in real-time
    func fetchUserDataRealTime(completion: @escaping (DataSnapshot?) -> Void) {
        dbRef.child("users").observe(.value) { snapshot in
            completion(snapshot)
        }
    }
    
    // Save user data
    func saveUserData(userId: String, data: [String: Any]) {
        dbRef.child("users").child(userId).setValue(data) { error, _ in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            }
        }
    }
    
    // Method to follow a user
        func followUser(currentUserId: String, userIdToFollow: String, completion: @escaping (Bool, Error?) -> Void) {
            let followersRef = dbRef.child("followers").child(userIdToFollow)
            let followingRef = dbRef.child("following").child(currentUserId)

            // Add current user to the followed user's followers list
            followersRef.child(currentUserId).setValue(true) { error, _ in
                if let error = error {
                    completion(false, error)
                    return
                }

                // Add followed user to the current user's following list
                followingRef.child(userIdToFollow).setValue(true) { error, _ in
                    if let error = error {
                        completion(false, error)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }

        // Method to unfollow a user
        func unfollowUser(currentUserId: String, userIdToUnfollow: String, completion: @escaping (Bool, Error?) -> Void) {
            let followersRef = dbRef.child("followers").child(userIdToUnfollow)
            let followingRef = dbRef.child("following").child(currentUserId)

            // Remove current user from the followed user's followers list
            followersRef.child(currentUserId).removeValue { error, _ in
                if let error = error {
                    completion(false, error)
                    return
                }

                // Remove followed user from the current user's following list
                followingRef.child(userIdToUnfollow).removeValue { error, _ in
                    if let error = error {
                        completion(false, error)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }

        // Method to check if a user is following another user
        func checkFollowingStatus(currentUserId: String, userIdToFollow: String, completion: @escaping (Bool, Error?) -> Void) {
            let followingRef = dbRef.child("following").child(currentUserId)

            followingRef.child(userIdToFollow).observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    completion(true, nil) // User is following
                } else {
                    completion(false, nil) // User is not following
                }
            } withCancel: { error in
                completion(false, error)
            }
        }

        // Fetch list of followers for a user
        func fetchFollowers(for userId: String, completion: @escaping ([String]) -> Void) {
            let followersRef = dbRef.child("followers").child(userId)

            followersRef.observeSingleEvent(of: .value) { snapshot in
                var followers: [String] = []

                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        followers.append(childSnapshot.key)
                    }
                }
                completion(followers)
            }
        }
    
    // Like or unlike a post
    func likePost(postId: String, userId: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        let postRef = dbRef.child("posts").child(postId)
        
        postRef.runTransactionBlock { (currentData) -> TransactionResult in
            guard var post = currentData.value as? [String: Any] else {
                return TransactionResult.success(withValue: currentData)
            }
            
            var likes = post["likes"] as? Int ?? 0
            var likedBy = post["likedBy"] as? [String: Bool] ?? [:]
            
            if likedBy[userId] == nil {
                likes += 1
                likedBy[userId] = true
            } else {
                likes -= 1
                likedBy.removeValue(forKey: userId)
            }
            
            post["likes"] = likes
            post["likedBy"] = likedBy
            
            currentData.value = post
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { [weak self] error, _, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Failed to update like count: \(error.localizedDescription)")
                }
                completion(error)
            }
        }
    }
    
}
