//
//  Post.swift
//  conectivity
//
//  Created by Dilip on 2024-10-07.
//

import Foundation
import UIKit

struct Post: Identifiable {
    var postId: String
    var userId: String
    var postImageUrl: String
    var caption: String
    var likeCount: Int
    var commentCount: Int
    var timestamp: Double
    var likedByCurrentUser: Bool
    var userData: UserData? // Optional property to hold user data
    
    var id: String { postId }
}

struct UserData {
    var userName: String
    var profileImage: UIImage
}

