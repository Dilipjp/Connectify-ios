//
//  AdminUsersView.swift
//  conectivity
//
//  Created by Dilip on 2024-10-31.
//

import SwiftUI
import FirebaseDatabase

struct User2: Identifiable {
    var id: String { userId }
    let userId: String
    var userName: String
    var userProfileImage: String
    var userStatus: String
}

struct AdminUsersView: View {
    @State private var allUsers: [User2] = []
    @State private var showConfirmation = false
    @State private var selectedUser: User2?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(allUsers) { user in
                        VStack {
                            HStack(spacing: 15) {
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
                            }
                            
                            // Row for View Posts and Activate/Deactivate buttons
                            HStack {
                                // View Posts Button
                                NavigationLink(destination: AdminUserPostsView(userId: user.userId)) {
                                    Text("Posts")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.black)
                                        .cornerRadius(8)
                                }
                                
                                // Toggle User Status Button with Confirmation Alert
                                Button(action: {
                                    selectedUser = user
                                    showConfirmation = true
                                }) {
                                    Text(user.userStatus == "active" ? "Deactivate" : "Activate")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(user.userStatus == "active" ? Color.red : Color.black)
                                        .cornerRadius(8)
                                }
                                .alert(isPresented: $showConfirmation) {
                                    Alert(
                                        title: Text("Confirm Action"),
                                        message: Text("Are you sure you want to \(selectedUser?.userStatus == "active" ? "deactivate" : "activate") \(selectedUser?.userName ?? "")?"),
                                        primaryButton: .destructive(Text("Confirm")) {
                                            if let userToUpdate = selectedUser {
                                                toggleUserStatus(for: userToUpdate)
                                            }
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                            .padding(.top, 8)
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
            .navigationBarBackButtonHidden(true)
            .onAppear(perform: loadAllUsers)
        }
    }

    func loadAllUsers() {
        let dbRef = Database.database().reference().child("users")
        
        dbRef.observeSingleEvent(of: .value) { snapshot in
            guard let usersData = snapshot.value as? [String: Any] else {
                print("No data found in 'users' node.")
                return
            }
            
            var tempUsers: [User2] = []
            
            for (key, value) in usersData {
                if let userData = value as? [String: Any],
                   let userRole = userData["userRole"] as? String,
                   userRole == "User",
                   let userName = userData["userName"] as? String,
                   let userStatus = userData["userStatus"] as? String,
                   let userProfileImage = userData["userProfileImage"] as? String {
                    
                    let user = User2(userId: key, userName: userName, userProfileImage: userProfileImage, userStatus: userStatus)
                    tempUsers.append(user)
                }
            }
            
            self.allUsers = tempUsers
        }
    }

    func toggleUserStatus(for user: User2) {
        let dbRef = Database.database().reference().child("users").child(user.userId)
        let newStatus = user.userStatus == "active" ? "deactivated" : "active"
        
        dbRef.updateChildValues(["userStatus": newStatus]) { error, _ in
            if let error = error {
                print("Error updating status: \(error.localizedDescription)")
            } else {
                if let index = self.allUsers.firstIndex(where: { $0.userId == user.userId }) {
                    self.allUsers[index].userStatus = newStatus
                }
                print("User status updated successfully")
            }
        }
    }
}

#Preview {
    AdminUsersView()
}

