//
//  CommentView.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-02.
//

import SwiftUI

struct CommentInputView: View {
    @State private var commentText: String = ""
    var postId: String
    var userId: String
    var username: String
    var onCommentPosted: () -> Void
    
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        HStack {
            TextField("Add a comment...", text: $commentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: postComment) {
                Text("Post")
                    .foregroundColor(.blue)
            }
            .disabled(commentText.isEmpty)
        }
    }

    private func postComment() {
        firebaseService.postComment(postId: postId, userId: userId, username: username, text: commentText) { success, error in
            if success {
                commentText = ""
                onCommentPosted() // Notify the parent view to refresh comments
            } else {
                print("Error posting comment: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
