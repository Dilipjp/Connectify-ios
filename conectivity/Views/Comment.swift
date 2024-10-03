//
//  Comment.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-02.
//

import Foundation

struct Comment: Identifiable {
    var id: String = UUID().uuidString
    var postId: String
    var userId: String
    var username: String
    var text: String
    var timestamp: TimeInterval
    
    init(postId: String, userId: String, username: String, text: String) {
            self.id = UUID().uuidString  // Generate a unique ID
            self.postId = postId
            self.userId = userId
            self.username = username
            self.text = text
            self.timestamp = Date().timeIntervalSince1970  // Current timestamp
        }
}
