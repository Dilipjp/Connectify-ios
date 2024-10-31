//
//  ModeratorUsersView.swift
//  conectivity
//
//  Created by Santhosh Nallapati on 2024-10-31.
//

import SwiftUI
import FirebaseDatabase

struct User1: Identifiable {
    var id: String { userId }
    let userId: String
    var userName: String
    var userProfileImage: String
    var userStatus: String
}

struct ModeratorUsersView: View {
    @State private var allUsers: [User1] = []
    @State private var showAlert = false
    @State private var selectedUserId: String = ""
    @State private var alertMessage: String = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(allUsers) { user in
                        VStack {
                            HStack(spacing: 15) {
                                // User Profile Image with Loading & Error Handling
                                AsyncImage(url: URL(string: user.userProfileImage)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                                                    Text(user.userName)
                                                                        .font(.title3)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundColor(.primary)
                                                                    Text(user.userStatus)
                                                                        .font(.subheadline)
                                                                        .foregroundColor(.secondary)
                                                                }
                                                                
                                                                Spacer()
                                // View Posts Button with NavigationLink
                                                           NavigationLink(destination: ModeratorUserPostsView(userId: user.userId)) {
                                                               Text("View Posts")
                                                                   .font(.subheadline)
                                                                   .fontWeight(.medium)
                                                                   .foregroundColor(.white)
                                                                   .frame(maxWidth: .infinity)
                                                                   .padding(.vertical, 8)
                                                                   .background(Color.black)
                                                                   .cornerRadius(8)
                                                                   .padding(.top, 8)
                                                           }
                                                       }
                                                       .padding()
                                                       .background(LinearGradient(
                                                           gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                                                           startPoint: .topLeading,
                                                           endPoint: .bottomTrailing
                                                       ))
                                                       .cornerRadius(12)
                                                       .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                                                   }
                                               }
                                               .padding(.horizontal)
                                           }
                                           .navigationTitle("All Users")
                                           .alert(isPresented: $showAlert) {
                                               Alert(
                                                   title: Text("Warning"),
                                                   message: Text(alertMessage),
                                                   primaryButton: .default(Text("Yes"), action: {
                                                       sendWarning(to: selectedUserId)
                                                   }),
                                                   secondaryButton: .cancel()
                                               )
                                           }
                                           .onAppear(perform: loadAllUsers)
                                       }
                                   }                    }
                            }
                            
                        
func loadAllUsers() {
    
}

private func sendWarning(to userId: String) {
        print("Sending warning to user: \(userId)")
    }

            
        
    
    

                

#Preview {
    ModeratorUsersView()
}
