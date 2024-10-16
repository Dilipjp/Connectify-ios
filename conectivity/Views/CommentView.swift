//
//  CommentView.swift
//  connectify
//
//  Created by Dilip on 2024-10-15.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct CommentView: View {
    let postId: String
    
    // Make sure all state variables and database references are accessible
    @State private var comments: [String: Comment] = [:]
    @State private var newCommentText: String = ""
    @State private var isLoading = true
    private var dbRef = Database.database().reference()

    // Explicitly declare the public initializer
    init(postId: String) {
        self.postId = postId
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(comments.keys.sorted(), id: \.self) { key in
                        if let comment = comments[key] {
                            HStack {
                                Text(comment.userName)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text(comment.commentText)
                                    .font(.body)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                HStack {
                    TextField("Add a comment...", text: $newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        addComment()
                    }) {
                        Text("Send")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchComments()
        }
    }

    func fetchComments() {
        dbRef.child("posts").child(postId).child("comments").observeSingleEvent(of: .value) { snapshot in
            if let commentsDict = snapshot.value as? [String: Any] {
                for (key, value) in commentsDict {
                    if let commentData = value as? [String: Any],
                       let commentText = commentData["commentText"] as? String,
                       let userId = commentData["userId"] as? String,
                       let userName = commentData["userName"] as? String {
                        let comment = Comment(commentText: commentText, userId: userId, userName: userName)
                        self.comments[key] = comment
                    }
                }
            }
            self.isLoading = false
        }
    }

    func addComment() {
        guard !newCommentText.isEmpty, let userId = Auth.auth().currentUser?.uid else { return }
        
        let commentId = UUID().uuidString
        let comment = ["commentText": newCommentText, "userId": userId, "userName": "YourName"] // Replace "YourName" with actual user name logic

        dbRef.child("posts").child(postId).child("comments").child(commentId).setValue(comment) { error, _ in
            if let error = error {
                print("Error adding comment: \(error.localizedDescription)")
            } else {
                newCommentText = ""
                fetchComments() // Optionally refresh comments here
            }
        }
    }
}

struct Comment {
    let commentText: String
    let userId: String
    let userName: String
}


