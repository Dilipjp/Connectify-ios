//
//  Post.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-04.
//

import Foundation
import Firebase

struct Post: Identifiable {
    let id: String
    let userId: String
    let postImageUrl: String
    let caption: String
    let timestamp: Int // Add timestamp property
    var comments: [Comment] = []
    var userData: UserData? = nil // For user profile info

    // Convert Firebase snapshot to Post object
    static func fromSnapshot(snapshot: [String: Any]) -> Post? {
        guard let userId = snapshot["userId"] as? String,
              let postImageUrl = snapshot["postImageUrl"] as? String,
              let caption = snapshot["caption"] as? String,
              let timestamp = snapshot["timestamp"] as? Int else { // Ensure timestamp is fetched
            return nil
        }
        
        let postId = snapshot["postId"] as? String ?? UUID().uuidString
        return Post(id: postId, userId: userId, postImageUrl: postImageUrl, caption: caption, timestamp: timestamp)
    }
}
