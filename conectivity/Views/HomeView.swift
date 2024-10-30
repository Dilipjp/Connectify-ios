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

            PostScreen()  // Pass actual data
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
