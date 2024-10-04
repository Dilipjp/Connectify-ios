//
//  Comment.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-02.
//

import Foundation

struct Comment: Identifiable {
    var id: String  // Unique identifier for the comment (Firebase key)
    var postId: String
    var userId: String
    var username: String
    var text: String
    var timestamp: TimeInterval // This will be set based on fetched data

    // Initializer for creating a new comment
    init(postId: String, userId: String, username: String, text: String) {
        self.id = UUID().uuidString  // Generate a unique ID for new comments
        self.postId = postId
        self.userId = userId
        self.username = username
        self.text = text
        self.timestamp = Date().timeIntervalSince1970  // Current timestamp for new comments
    }

    // Initializer for fetched comments
    init(id: String, postId: String, userId: String, username: String, text: String, timestamp: TimeInterval) {
        self.id = id // Use the Firebase key as ID
        self.postId = postId
        self.userId = userId
        self.username = username
        self.text = text
        self.timestamp = timestamp // Set the timestamp from fetched data
    }
}
