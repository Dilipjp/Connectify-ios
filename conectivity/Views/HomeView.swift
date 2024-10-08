import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            FollowersView(currentUserId: currentUserId) // Update to FollowersView
                .tabItem {
                    Label("Followers", systemImage: "person.2.fill")
                }

            PostScreen()
                .tabItem {
                    Label("Post", systemImage: "plus.circle.fill")
                }

            ProfileScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(FirebaseService())
    }
}
