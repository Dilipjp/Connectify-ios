//
//  ModeratorUserPostsView.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-31.
//

import SwiftUI

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

public struct ModeratorUserPostsView: View {
    public let userId: String

    @State private var userPosts: [Post] = []
    @State private var isLoading = true
    @State private var selectedPost: Post? = nil
    @State private var showEditPostView = false
    @State private var showWarningAlert = false
    @State private var warningMessage = "Please review the content of this post."

    private var dbRef = Database.database().reference()

    public init(userId: String) {
        self.userId = userId
    }

    public var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading posts...")
            } else if userPosts.isEmpty {
                Text("No posts available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(userPosts, id: \.postId) { post in
                        VStack(alignment: .leading, spacing: 15) {
                            // Post Caption
                            Text(post.caption)
                                .font(.headline)
                        
