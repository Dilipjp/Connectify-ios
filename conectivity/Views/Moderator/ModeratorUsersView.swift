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
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
}
                

#Preview {
    ModeratorUsersView()
}
