import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class FirebaseService: ObservableObject {
    @Published var isLoggedIn: Bool = false
    private var dbRef = Database.database().reference()
    
    init() {
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            self.isLoggedIn = user != nil
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let _ = result {
                self.isLoggedIn = true
                completion(true, nil)
            } else {
                self.isLoggedIn = false
                completion(false, error)  // Pass the error object directly
            }
        }
    }
    
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
                    completion(error == nil, error)  // Pass the error object directly
                }
            } else {
                completion(false, error)  // Pass the error object directly
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error)  // Pass the error object directly
            } else {
                completion(true, nil)
            }
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
    }
    
    func fetchUserData(completion: @escaping (DataSnapshot?, Error?) -> Void) {
            dbRef.child("users").observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    completion(snapshot, nil)
                } else {
                    completion(nil, NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User data not found"]))
                }
            } withCancel: { error in
                completion(nil, error)  // Pass the error object directly
            }
        }
    func saveUserData(userId: String, data: [String: Any]) {
        dbRef.child("users").child(userId).setValue(data)
    }
    
    func postComment(postId: String, userId: String, username: String, text: String, completion: @escaping (Bool, Error?) -> Void) {
        let comment = Comment(postId: postId, userId: userId, username: username, text: text)
        
        // Store comment in Firebase under the post ID
        let commentRef = self.dbRef.child("comments").child(postId).child(comment.id)
        
        commentRef.setValue([
            "userId": userId,
            "username": username,
            "text": text,
            "timestamp": comment.timestamp
        ]) { error, _ in
            completion(error == nil, error)  // Pass the error object directly
        }
    }
    
    func fetchComments(for postId: String, completion: @escaping ([Comment], Error?) -> Void) {
        dbRef.child("comments").child(postId).observeSingleEvent(of: .value) { snapshot in
            var comments: [Comment] = []
            
            // Iterate through the children of the snapshot
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let value = childSnapshot.value as? [String: Any] {
                    let comment = Comment(
                        id: childSnapshot.key,
                        postId: postId,
                        userId: value["userId"] as? String ?? "",
                        username: value["username"] as? String ?? "",
                        text: value["text"] as? String ?? "",
                        timestamp: value["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
                    )
                    comments.append(comment)
                }
            }

            completion(comments, nil)  // Return comments and no error
        } withCancel: { error in
            completion([], error)  // Return an empty array and the error
        }
    }

    }
