//
//  CommentView.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-02.
//

import SwiftUI

struct CommentView: View {
    @State private var comments: [Comment] = []
    @State private var commentText = ""
    var body: some View {
        List(comments) { comment in
                        VStack(alignment: .leading) {
                            Text(comment.username).font(.headline)
                            Text(comment.text).font(.subheadline)
                            Text(Date(timeIntervalSince1970: comment.timestamp), style: .time)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
        HStack {
                       TextField("Enter your comment", text: $commentText)
                           .padding()
                           .background(Color(.systemGray6))
                           .cornerRadius(8)
                       
                       Button(action: {
                           postComment()
                       }) {
                           Image(systemName: "paperplane.fill")
                               .font(.title)
                               .padding()
                       }
                   }
                   .padding()
               }
//        .onAppear {
//                   loadComments()
//               }
               
}

private func postComment() {
}

private func loadComments() {
}

#Preview {
    CommentView()
}
