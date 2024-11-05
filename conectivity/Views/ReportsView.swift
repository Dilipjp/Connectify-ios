//
//  ReportsView.swift
//  conectivity
//
//  Created by Subash Gaddam on 2024-11-05.
//

struct Report: Identifiable {
    var id: String
    var postId: String
    var reason: String
    var timestamp: TimeInterval
    var reporterId: String
    var caption: String?
    var uploaderName: String?
    var reporterName: String?
    var postImageUrl: String?
}

struct ReportsView: View {
    var body: some View {
        
    }
}
#Preview {
    ReportsView()
}
