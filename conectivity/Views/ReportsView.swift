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
    
#Preview {
    ReportsView()
}
