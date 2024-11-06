//
//  CommentView.swift
//  conectivity
//
//  Created by Dilip on 2024-10-17.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct Comment1: Identifiable {
    var id: String
    var commentText: String
    var timestamp: TimeInterval
    var userId: String
    var userName: String?
    var userProfileImage: String?
}

struct CommentView: View {
    var postId: String
    @State private var comments: [Comment1] = []
    @State private var isLoading = true
    @State private var newCommentText = ""
    @State private var isSubmitting = false
    @State private var editingCommentId: String? = nil
    @State private var currentUserId: String? = nil

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Comments...")
            } else if comments.isEmpty {
                Text("No comments available")
                    .font(.headline)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(comments, id: \.id) { comment in
                            HStack(alignment: .top, spacing: 12) {
                                if let userProfileImage = comment.userProfileImage {
                                    AsyncImage(url: URL(string: userProfileImage)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.5))
                                            .frame(width: 50, height: 50)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 5) {
                                    if let userName = comment.userName {
                                        Text(userName)
                                            .font(.headline)
                                    }
                                    Text(comment.commentText)
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    
                                    if let commentTimestamp = formatTimestamp(comment.timestamp) {
                                        Text(commentTimestamp)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }

                                Spacer()

                                // Show edit/delete options if the comment belongs to the current user
                                if comment.userId == currentUserId {
                                    Menu {
                                        Button(action: {
                                            // Trigger editing mode
                                            editingCommentId = comment.id
                                            newCommentText = comment.commentText
                                        }) {
                                            Text("Edit")
                                        }
                                        Button(action: {
                                            // Delete comment
                                            deleteComment(commentId: comment.id)
                                        }) {
                                            Text("Delete").foregroundColor(.red)
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .padding()
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // New Comment Input
            VStack {
                HStack {
                    TextField(editingCommentId == nil ? "Add a comment..." : "Edit your comment...", text: $newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        if editingCommentId != nil {
                            // Edit the comment
                            updateComment(commentId: editingCommentId!)
                        } else {
                            // Add a new comment
                            submitComment()
                        }
                    }) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(editingCommentId == nil ? "Post" : "Update")
                                .bold()
                        }
                    }
                    .padding(.horizontal)
                    .disabled(newCommentText.isEmpty || isSubmitting)
                }
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            fetchComments(for: postId)
            fetchCurrentUserId()
        }
        .navigationBarTitle("Comments", displayMode: .inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // Fetch the current user's ID
    func fetchCurrentUserId() {
        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
        }
    }

    // Submit a new comment
    func submitComment() {
        guard let user = Auth.auth().currentUser else { return }
        isSubmitting = true
        let commentId = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // milliseconds
        
        let newComment = [
            "commentText": newCommentText,
            "timestamp": timestamp,
            "userId": user.uid
        ] as [String: Any]
        
        let ref = Database.database().reference().child("posts").child(postId).child("comments").child(commentId)
        
        ref.setValue(newComment) { error, _ in
            if let error = error {
                print("Error submitting comment: \(error)")
            } else {
                fetchUserDetails(for: user.uid) { userName, userProfileImage in
                    let comment = Comment1(
                        id: commentId,
                        commentText: newCommentText,
                        timestamp: TimeInterval(timestamp),
                        userId: user.uid,
                        userName: userName,
                        userProfileImage: userProfileImage
                    )
                    self.comments.append(comment)
                    self.newCommentText = ""
                }
                increaseCommentCount()

                
            }
            isSubmitting = false
        }
    }
   
    

    

    // Update an existing comment
    
    func updateComment(commentId: String) {
        guard let user = Auth.auth().currentUser else { return }
        isSubmitting = true
        let timestamp = Date().timeIntervalSince1970 * 1000 // milliseconds
        
        let updatedComment = [
            "commentText": newCommentText,
            "timestamp": timestamp,
            "userId": user.uid
        ] as [String: Any]
        
        let ref = Database.database().reference().child("posts").child(postId).child("comments").child(commentId)
        
        ref.updateChildValues(updatedComment) { error, _ in
            if let error = error {
                print("Error updating comment: \(error)")
            } else {
                // Update the comment in the local list
                if let index = self.comments.firstIndex(where: { $0.id == commentId }) {
                    self.comments[index].commentText = newCommentText
                    self.comments[index].timestamp = timestamp
                }
                self.newCommentText = ""
                self.editingCommentId = nil
            }
            isSubmitting = false
        }
    }

    // Delete a comment
    func deleteComment(commentId: String) {
        let ref = Database.database().reference().child("posts").child(postId).child("comments").child(commentId)
        
        ref.removeValue { error, _ in
            if let error = error {
                print("Error deleting comment: \(error)")
            } else {
                // Remove the comment from the local list
                self.comments.removeAll { $0.id == commentId }
                decreaseCommentCount()

            }
        }
    }

    // Fetch comments for the given postId
    func fetchComments(for postId: String) {
        let ref = Database.database().reference().child("posts").child(postId).child("comments")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            var fetchedComments: [Comment1] = []
            
            if let commentsData = snapshot.value as? [String: [String: Any]] {
                for (commentId, commentDict) in commentsData {
                    if let commentText = commentDict["commentText"] as? String,
                       let timestamp = commentDict["timestamp"] as? TimeInterval,
                       let userId = commentDict["userId"] as? String {
                        
                        let comment = Comment1(id: commentId, commentText: commentText, timestamp: timestamp, userId: userId)
                        fetchUserDetails(for: userId) { userName, userProfileImage in
                            if let index = fetchedComments.firstIndex(where: { $0.id == commentId }) {
                                fetchedComments[index].userName = userName
                                fetchedComments[index].userProfileImage = userProfileImage
                                self.comments = fetchedComments
                            }
                        }
                        fetchedComments.append(comment)
                    }
                }
                self.comments = fetchedComments.sorted(by: { $0.timestamp < $1.timestamp })
            }
            self.isLoading = false
        }
    }
    


    // increase commentCount in the posts node
    func increaseCommentCount() {
        let postRef = Database.database().reference().child("posts").child(postId)
        
        postRef.runTransactionBlock { currentData -> TransactionResult in
            if var post = currentData.value as? [String: Any],
               let commentCount = post["commentCount"] as? Int {
                post["commentCount"] = commentCount + 1
                currentData.value = post
                return .success(withValue: currentData)
            }
            return .success(withValue: currentData)
        } andCompletionBlock: { error, _, _ in
            if let error = error {
                print("Error updating comment count: \(error)")
            } else {
                print("Comment count updated successfully.")
            }
        }
    }
    

    // decrease commentCount in the posts node
    func decreaseCommentCount() {
        let ref = Database.database().reference().child("posts").child(postId).child("commentCount")
        let newCommentCount = self.comments.count
        ref.setValue(newCommentCount) { error, _ in
            if let error = error {
                print("Error updating comment count: \(error)")
            } else {
                print("Comment count updated successfully")
            }
        }
    }


    // Fetch user details
    func fetchUserDetails(for userId: String, completion: @escaping (String?, String?) -> Void) {
        let userRef = Database.database().reference().child("users").child(userId)
        
        userRef.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                let userName = userData["userName"] as? String
                let userProfileImage = userData["userProfileImage"] as? String
                completion(userName, userProfileImage)
            } else {
                completion(nil, nil)
            }
        }
    }

    // Helper function to format the timestamp
    func formatTimestamp(_ timestamp: TimeInterval) -> String? {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommentView(postId: "examplePostId")
        }
    }
}

