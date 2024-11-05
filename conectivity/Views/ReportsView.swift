//
//  ReportsView.swift
//  conectivity
//
//  Created by Dilip on 2024-11-05.
//

import SwiftUI
import FirebaseDatabase

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
    @State private var reports: [Report] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(reports) { report in
                        VStack(alignment: .leading, spacing: 8) {
                            if let postImageUrl = report.postImageUrl, let caption = report.caption, let uploaderName = report.uploaderName, let reporterName = report.reporterName {
                                
                                // Display Post Image
                                AsyncImage(url: URL(string: postImageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                        .cornerRadius(10)
                                } placeholder: {
                                    ProgressView()
                                        .frame(height: 200)
                                }
                                
                                // Display Post Details
                                Text("Caption: \(caption)")
                                    .font(.headline)
                                Text("Uploader: \(uploaderName)")
                                    .font(.subheadline)
                                Text("Reporter: \(reporterName)")
                                    .font(.subheadline)
                                Text("Reason: \(report.reason)")
                                    .font(.subheadline)
                                Text("Date: \(Date(timeIntervalSince1970: report.timestamp / 1000).formatted())")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Reports")
            .onAppear(perform: loadReports)
        }
    }
    
    func loadReports() {
        let dbRef = Database.database().reference()
        dbRef.child("reports").observeSingleEvent(of: .value) { snapshot in
            guard let reportsData = snapshot.value as? [String: Any] else {
                print("No data found in 'reports' node.")
                return
            }
            
            var tempReports: [Report] = []
            
            for (reportId, reportValue) in reportsData {
                if let reportDict = reportValue as? [String: Any],
                   let postId = reportDict["postId"] as? String,
                   let reason = reportDict["reason"] as? String,
                   let timestamp = reportDict["timestamp"] as? TimeInterval,
                   let reporterId = reportDict["userId"] as? String {
                    
                    var report = Report(id: reportId, postId: postId, reason: reason, timestamp: timestamp, reporterId: reporterId)
                    
                    // Fetch post details including caption, uploader username, and image URL
                    dbRef.child("posts").child(postId).observeSingleEvent(of: .value) { postSnapshot in
                        if let postData = postSnapshot.value as? [String: Any],
                           let caption = postData["caption"] as? String,
                           let uploaderId = postData["userId"] as? String,
                           let postImageUrl = postData["postImageUrl"] as? String {
                            
                            report.caption = caption
                            report.postImageUrl = postImageUrl
                            
                            // Fetch uploader's username
                            dbRef.child("users").child(uploaderId).observeSingleEvent(of: .value) { userSnapshot in
                                if let userData = userSnapshot.value as? [String: Any],
                                   let uploaderName = userData["userName"] as? String {
                                    report.uploaderName = uploaderName
                                    
                                    // Fetch reporter's username
                                    dbRef.child("users").child(reporterId).observeSingleEvent(of: .value) { reporterSnapshot in
                                        if let reporterData = reporterSnapshot.value as? [String: Any],
                                           let reporterName = reporterData["userName"] as? String {
                                            report.reporterName = reporterName
                                            
                                            // Update the report in the array
                                            DispatchQueue.main.async {
                                                tempReports.append(report)
                                                self.reports = tempReports.sorted { $0.timestamp > $1.timestamp }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ReportsView()
}



