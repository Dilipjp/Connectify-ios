import SwiftUI
import FirebaseDatabase

struct LikeView: View {
    @State private var likesCount: Int = 0
    @State private var isLiked: Bool = false
    let postId: String
    let userId: String

    var body: some View {
        HStack {
            Button(action: {
                toggleLike()
            }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .gray)
            }
            Text("\(likesCount)")
                .font(.subheadline)
        }
        .onAppear {
            fetchLikeStatus()
        }
    }

    // Fetch initial like status
    private func fetchLikeStatus() {
        let ref = Database.database().reference().child("posts").child(postId)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let post = snapshot.value as? [String: Any],
               let likes = post["likes"] as? Int,
               let likedBy = post["likedBy"] as? [String: Bool] {
                self.likesCount = likes
                self.isLiked = likedBy[userId] != nil
            }
        }
    }

    // Function to like/unlike the post
    private func toggleLike() {
        let ref = Database.database().reference().child("posts").child(postId)

        ref.runTransactionBlock { currentData -> TransactionResult in
            if var post = currentData.value as? [String: Any] {
                var likes = post["likes"] as? Int ?? 0
                var likedBy = post["likedBy"] as? [String: Bool] ?? [:]

                if likedBy[userId] == nil {
                    // User has not liked the post yet
                    likes += 1
                    likedBy[userId] = true
                    self.isLiked = true
                } else {
                    // User has already liked the post
                    likes -= 1
                    likedBy.removeValue(forKey: userId)
                    self.isLiked = false
                }

                post["likes"] = likes
                post["likedBy"] = likedBy
                currentData.value = post
                DispatchQueue.main.async {
                    self.likesCount = likes
                }
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }
    }
}
