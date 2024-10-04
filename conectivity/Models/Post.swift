//
//  Post.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-04.
//

import Foundation

struct Post: Identifiable {
    let id = UUID()
    let postId: String
    let userId: String
    let postImageUrl: String
    let caption: String
    var userData: UserData?
    var comments: [Comment]
}
