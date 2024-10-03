//
//  HomeView.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            HomeScreen()  // Use the renamed HomeScreen
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            FollowersScreen()  // Use the renamed FollowersScreen
                .tabItem {
                    Label("Followers", systemImage: "person.2.fill")
                }

            PostScreen(postId: <#String#>, userId: <#String#>, username: <#String#>)  // Use the renamed PostScreen
                .tabItem {
                    Label("Post", systemImage: "plus.circle.fill")
                }

            ProfileScreen()  // Use the renamed ProfileScreen
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}



