//
//  HomeTab.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseAuth

struct HomeScreen: View {
    @State private var posts: [Post] = []
    @State private var loadingUsers: [Bool] = []
    @State private var showShareSheet = false
    @State private var shareContent: String = ""
    @State private var showCommentSheet: Bool = false
    @State private var selectedPost: Post?
    @State private var newComment: String = ""
    // Report-related states
    @State private var showReportSheet: Bool = false
    @State private var reportReason: String = ""
    @State private var postToReport: Post?
    @State private var reportSuccessMessage = ""
    @State private var showReportSuccessMessage = false


    private var dbRef = Database.database().reference()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(posts.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 10) {
                            // User Profile Image and Name
                            if let userData = posts[index].userData {
                                HStack {
                                    Image(uiImage: userData.profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                        .padding(5)

                                    Text(userData.userName)
                                        .font(.headline)
                                        .padding(.leading, 8)

                                    Spacer()
                                    // Report Button
                                                                       Button(action: {
                                                                           postToReport = posts[index]
                                                                           showReportSheet.toggle()
                                                                       }) {
                                                                           Image(systemName: "exclamationmark.triangle")
                                                                               .foregroundColor(.red)
                                                                       }
                                }
                                .padding(.horizontal, 10)
                                .padding(.top, 5)
                            } else if loadingUsers[index] {
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 40, height: 40)
                                        .padding(5)

                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 100, height: 20)

                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.top, 5)
                            }

                            // Post Image
                            AsyncImage(url: URL(string: posts[index].postImageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            
                            // Display Post Location Name with Icon
                           

                            if let locationName = posts[index].locationName, !locationName.isEmpty {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse") // Location icon
                                        .foregroundColor(.red)
                                    Text(locationName)

                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 10)

                            }





                            // Like, Comment, Share Icons with Count
                            HStack {
                                // Like Button
                                Button(action: {
                                    toggleLike(for: posts[index], at: index)
                                }) {
                                    HStack {
                                        Image(systemName: posts[index].likedByCurrentUser ? "heart.fill" : "heart")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(posts[index].likedByCurrentUser ? .red : .gray)
                                        Text("\(posts[index].likeCount)")
                                            .font(.subheadline)
                                            .padding(.leading, 4)
                                            .foregroundColor(.black)
                                    }
                                }
                                .disabled(posts[index].isLikeButtonDisabled)
                                .padding(.leading, 10)

                                // Comment Button with NavigationLink
                                NavigationLink(destination: CommentView(postId: posts[index].postId)) {
                                    HStack {
                                        Image(systemName: "message")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.black)
                                        Text("\(posts[index].commentCount)")
                                            .font(.subheadline)
                                            .padding(.leading, 4)
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(.leading, 10)

                                // Share Button
                                Button(action: {
                                    shareContent = posts[index].caption
                                    showShareSheet = true
                                }) {
                                    Image(systemName: "paperplane")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.black)
                                }
                                .padding(.leading, 10)
                            }
                            .padding(.top, 5)
                            .padding(.bottom, 10)

                            // Post Caption
                            Text(posts[index].caption)
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Connectify")
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [shareContent])
            }
            .sheet(isPresented: $showReportSheet) {
                            VStack {
                                Text("Report Post")
                                    .font(.title)
                                    .padding()
                                
                                TextField("Reason for reporting...", text: $reportReason)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                
                                Button("Submit Report") {
                                    if let post = postToReport {
                                        submitReport(for: post, reason: reportReason)
                                    }
                                    showReportSheet = false
                                    reportReason = ""
                                }
                                .padding()
                                if showReportSuccessMessage {
                                            Text(reportSuccessMessage)
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                                .padding()
                                                .onAppear {
                                                    // Hide the message after a short delay
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                        showReportSuccessMessage = false
                                                    }
                                                }
                                        }
                            }
                            .padding()
                        }
            
            .onAppear {
                fetchPosts()  // Fetch posts when the view appears
            }
        }
    }


    struct ShareSheet: UIViewControllerRepresentable {
        var activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            let shareSheet = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            return shareSheet
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            // No updates needed
        }
    }

    func fetchPosts() {
        let currentUserId = Auth.auth().currentUser?.uid  // Get the current user's ID

        dbRef.child("posts").observe(.value) { snapshot in
            var newPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let postId = dict["postId"] as? String,
                   let userId = dict["userId"] as? String,
                   let postImageUrl = dict["postImageUrl"] as? String,
                   let caption = dict["caption"] as? String,
                   let locationName = dict["locationName"] as? String,
                   
                   let timestamp = dict["timestamp"] as? Double {
                    let locationName = dict["locationName"] as? String

                    let likeCount = dict["likeCount"] as? Int ?? 0
                    let commentCount = dict["commentCount"] as? Int ?? 0

                    let likesDict = dict["likes"] as? [String: Bool] ?? [:]
//                    let likedByCurrentUser = likesDict[currentUserId!] ?? false
                    let likedByCurrentUser = currentUserId != nil ? (likesDict[currentUserId!] ?? false) : false


                    let post = Post(
                        postId: postId,
                        userId: userId,
                        postImageUrl: postImageUrl,
                        locationName: locationName,
                        caption: caption,
                        likeCount: likeCount,
                        commentCount: commentCount,
                        timestamp: timestamp,
                        likedByCurrentUser: likedByCurrentUser
                    )

                    
                    newPosts.append(post)
                }
            }

            self.posts = newPosts.sorted(by: { $0.timestamp > $1.timestamp })
            self.loadingUsers = Array(repeating: true, count: self.posts.count)
            fetchUserDetails(for: self.posts)
        }
    }


    func fetchUserDetails(for posts: [Post]) {
        for (index, post) in posts.enumerated() {
            dbRef.child("users").child(post.userId).observeSingleEvent(of: .value) { snapshot in
                if let userDict = snapshot.value as? [String: Any],
                   let userName = userDict["userName"] as? String,
                   let userProfileImage = userDict["userProfileImage"] as? String,
                   let imageUrl = URL(string: userProfileImage) {

                    URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.posts[index].userData = UserData(userName: userName, profileImage: image)
                                self.loadingUsers[index] = false
                            }
                        }
                    }.resume()
                }
            }
        }
    }

    func toggleLike(for post: Post, at index: Int) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let postRef = dbRef.child("posts").child(post.postId)

        self.posts[index].isLikeButtonDisabled = true

        var updatedPost = self.posts[index]
        updatedPost.likedByCurrentUser.toggle()
        updatedPost.likeCount += updatedPost.likedByCurrentUser ? 1 : -1

        self.posts[index].likeCount = updatedPost.likeCount
        self.posts[index].likedByCurrentUser = updatedPost.likedByCurrentUser

        postRef.runTransactionBlock({ (currentData) -> TransactionResult in
            if var post = currentData.value as? [String: AnyObject] {
                var likes = post["likes"] as? [String: Bool] ?? [:]
                var likeCount = post["likeCount"] as? Int ?? 0

                if likes[currentUserId] != nil {
                    likes[currentUserId] = nil
                    likeCount = max(likeCount - 1, 0)
                } else {
                    likes[currentUserId] = true
                    likeCount += 1
                }

                post["likes"] = likes as AnyObject
                post["likeCount"] = likeCount as AnyObject
                currentData.value = post

                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { error, committed, snapshot in
            DispatchQueue.main.async {
                self.posts[index].isLikeButtonDisabled = false

                if let error = error {
                    print("Error updating like count: \(error.localizedDescription)")
                }
            }
        }
    }


//    func updateCommentCount(for post: Post) {
//        let postRef = dbRef.child("posts").child(post.postId)
//        postRef.child("commentCount").setValue(post.commentCount + 1) { error, _ in
//            if let error = error {
//                print("Error updating comment count: \(error.localizedDescription)")
//            }
//        }
//    }
    func submitReport(for post: Post, reason: String) {
        // Check if reason is empty
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            reportSuccessMessage = "Please provide a reason for reporting."
            showReportSuccessMessage = true
            return
        }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let reportId = dbRef.child("reports").childByAutoId().key ?? UUID().uuidString
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)  // Save timestamp in milliseconds
        
        let reportData: [String: Any] = [
            "postId": post.postId,
            "userId": currentUserId,
            "reason": reason,
            "timestamp": timestamp
        ]
        
        dbRef.child("reports").child(reportId).setValue(reportData) { error, _ in
            if let error = error {
                reportSuccessMessage = "Error submitting report: \(error.localizedDescription)"
            } else {
                reportSuccessMessage = "Report submitted successfully"
            }
            showReportSuccessMessage = true
        }
    }


}




struct Post: Identifiable {
    let id = UUID()
    let postId: String
    let userId: String
    let postImageUrl: String

    var locationName: String?

    let caption: String
    var likeCount: Int
    let commentCount: Int
    let timestamp: TimeInterval
    var likedByCurrentUser: Bool = false
    var isLikeButtonDisabled: Bool = false
    var userData: UserData?
    var comments: [Comment] = []  
}

struct Comment: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let commentText: String
    let timestamp: TimeInterval
}


// User data model
struct UserData {
    let userName: String
    let profileImage: UIImage
}
