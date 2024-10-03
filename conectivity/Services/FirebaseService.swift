//
//  FirebaseService.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class FirebaseService: ObservableObject {
    @Published var isLoggedIn: Bool = false
    private var dbRef = Database.database().reference()

    init() {
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            if let _ = user {
                self.isLoggedIn = true
            } else {
                self.isLoggedIn = false
            }
        }
    }


    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let _ = result {
                self.isLoggedIn = true
                completion(true, nil)
            } else if let error = error {
                self.isLoggedIn = false
                completion(false, error)
            }
        }
    }

    // Sign up with additional user information
        func signUp(email: String, password: String, userName: String, userBio: String, userRole: String, userProfileImage: String?, completion: @escaping (Bool, Error?) -> Void) {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let user = result?.user {
                    let userData: [String: Any] = [
                        "userEmail": email,
                        "userName": userName,
                        "userBio": userBio,
                        "userProfileImage": userProfileImage ?? "defaultProfileImageURL",
                        "userRole": userRole,
                        "userStatus": "active",
                        "userCreatedAt": [".sv": "timestamp"] // Use server timestamp
                    ]
                    
                    self.dbRef.child("users").child(user.uid).setValue(userData) { error, _ in
                        completion(error == nil, error)
                    }
                } else if let error = error {
                    completion(false, error)
                }
            }
        }

    func sendPasswordReset(email: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
    }

    func fetchUserData(completion: @escaping (DataSnapshot?) -> Void) {
        dbRef.child("users").observeSingleEvent(of: .value) { snapshot in
            completion(snapshot)
        }
    }

    func saveUserData(userId: String, data: [String: Any]) {
        dbRef.child("users").child(userId).setValue(data)
    }
    func likePost(postId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let ref = Database.database().reference()
        let postRef = ref.child("posts").child(postId)

        postRef.runTransactionBlock { (currentData) -> TransactionResult in
            if var post = currentData.value as? [String: Any] {
                var likes = post["likes"] as? Int ?? 0
                var likedBy = post["likedBy"] as? [String: Bool] ?? [:]

                if likedBy[userId] == nil {
                    // User has not liked the post yet
                    likes += 1
                    likedBy[userId] = true
                } else {
                    // User has already liked the post
                    likes -= 1
                    likedBy.removeValue(forKey: userId)
                }

                post["likes"] = likes
                post["likedBy"] = likedBy

                currentData.value = post
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, _, _ in
            completion(error)
        }
    }
}

