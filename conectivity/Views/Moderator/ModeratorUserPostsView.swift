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
                            // Display Post Image
                                                      if let url = URL(string: post.postImageUrl) {
                                                          AsyncImage(url: url) { image in
                                                              image
                                                                  .resizable()
                                                                  .scaledToFit()
                                                                  .frame(maxHeight: 250) // Limit image height
                                                                  .cornerRadius(8)
                                                          } placeholder: {
                                                              ProgressView()
                                                          }
                                                      }

                                                      // HStack for Edit, Delete, and Send Warning buttons
                                                      HStack {
                                                          Button(action: {
                                                              selectedPost = post
                                                              showEditPostView = true
                                                          }) {
                                                              Text("Edit")
                                                                  .font(.subheadline)
                                                                  .padding(.vertical, 8)
                                                                  .padding(.horizontal, 16)
                                                                  .background(Color.blue.opacity(0.1))
                                                                  .cornerRadius(8)
                                                          }
                                                          .buttonStyle(PlainButtonStyle()) // Prevents triggering unwanted effects
                                                          
                                                          Spacer()

                                                          Button(action: {
                                                              deletePost(postId: post.postId)
                                                          }) {
                                                              Text("Delete")
                                                                  .font(.subheadline)
                                                                  .padding(.vertical, 8)
                                                                  .padding(.horizontal, 16)
                                                                  .background(Color.red.opacity(0.1))
                                                                  .foregroundColor(.red)
                                                                  .cornerRadius(8)
                                                          }
                                                          .buttonStyle(PlainButtonStyle())

                                                          Spacer()

                                                          Button(action: {
                                                              selectedPost = post
                                                              showWarningAlert = true
                                                          }) {
                                                              Text("Send Warning")
                                                                  .font(.subheadline)
                                                                  .padding(.vertical, 8)
                                                                  .padding(.horizontal, 16)
                                                                  .background(Color.orange.opacity(0.1))
                                                                  .foregroundColor(.orange)
                                                                  .cornerRadius(8)
                                                          }
                                                          .buttonStyle(PlainButtonStyle())
                                                      }
                                                      .padding(.top, 10)
                                                  }
                                                  .padding(.vertical, 8) // Padding between posts
                                              }
                                          }
                                      }
                                  }
                                  .onAppear {
                                      fetchUserPosts()
                                  }
                                  .sheet(isPresented: $showEditPostView) {
                                      if let selectedPost = selectedPost {
                                          EditPostView(post: .constant(selectedPost))
                                      }
                                  }
                                  .alert(isPresented: $showWarningAlert) {
                                      Alert(
                                          title: Text("Send Warning"),
                                          message: Text("Are you sure you want to send a warning for this post?"),
                                          primaryButton: .destructive(Text("Send")) {
                                              if let post = selectedPost {
                                                  sendWarning(postId: post.postId)
                                              }
                                          },
                                          secondaryButton: .cancel()
                                      )
                                  }
                              }

