import UIKit

struct UserData {
    var userName: String         // Username of the post creator
    var profileImage: UIImage    // User's profile image
    
    init(userName: String, profileImage: UIImage) {
        self.userName = userName
        self.profileImage = profileImage
    }
}
