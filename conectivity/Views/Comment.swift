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
    var timestamp: TimeInterval = Date().timeIntervalSince1970
}
