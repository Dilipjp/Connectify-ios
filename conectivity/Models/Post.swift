import UIKit

struct Post {
    var postId: String           // Unique identifier for the post
    var userId: String           // ID of the user who made the post
    var postImageUrl: String     // URL for the post image
    var caption: String          // Caption text for the post
    var likeCount: Int           // Number of likes on the post
    var isLiked: Bool            // Whether the post is liked by the current user
    var userData: UserData?      // Additional user details like username and profile image
    
    init(postId: String, userId: String, postImageUrl: String, caption: String, likeCount: Int = 0, isLiked: Bool = false, userData: UserData? = nil) {
        self.postId = postId
        self.userId = userId
        self.postImageUrl = postImageUrl
        self.caption = caption
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.userData = userData
    }
}
