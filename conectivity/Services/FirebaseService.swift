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
                completion(false, error)
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
                    completion(error == nil, error)
                }
            } else {
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
    
    func fetchUserData(completion: @escaping (DataSnapshot?, Error?) -> Void) {
        dbRef.child("users").observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                completion(snapshot, nil)
            } else {
                completion(nil, NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User data not found"]))
            }
        }) { error in
            completion(nil, error)
        }
    }

    func saveUserData(userId: String, data: [String: Any]) {
        dbRef.child("users").child(userId).setValue(data)
    }
    
    // Updated to store comments inside posts
    func postComment(postId: String, userId: String, username: String, text: String, completion: @escaping (Bool, Error?) -> Void) {
        let commentId = UUID().uuidString // Generate a unique ID for the comment
        let commentData: [String: Any] = [
            "userId": userId,
            "username": username,
            "text": text,
            "timestamp": Date().timeIntervalSince1970 // Store timestamp
        ]
        
        // Store comment in Firebase under the post ID
        let commentRef = self.dbRef.child("posts").child(postId).child("comments").child(commentId)
        
        commentRef.setValue(commentData) { error, _ in
            completion(error == nil, error)
        }
    }
    
    // Updated to fetch comments from the posts
    func fetchComments(for postId: String, completion: @escaping ([Comment], Error?) -> Void) {
        dbRef.child("posts").child(postId).child("comments").getData { error, snapshot in
            // Initialize an empty array to store comments
            var comments: [Comment] = []
            
            // Check if there was an error fetching the data
            if let error = error {
                completion([], error)  // Return an empty array and the error
                return
            }
            
            // Ensure the snapshot is not nil and has children
            guard let snapshot = snapshot, snapshot.childrenCount > 0 else {
                // Handle the case where there are no comments found
                let noCommentsError = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "No comments found for this post."])
                completion([], noCommentsError)
                return
            }
            
            // Iterate through the snapshot's children
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let value = child.value as? [String: Any] {
                    let comment = Comment(
                        id: child.key,
                        postId: postId,
                        userId: value["userId"] as? String ?? "",
                        username: value["username"] as? String ?? "",
                        text: value["text"] as? String ?? "",
                        timestamp: value["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
                    )
                    comments.append(comment)
                }
            }
            
            // Return the list of comments and no error
            completion(comments, nil)
        }
    }
}
