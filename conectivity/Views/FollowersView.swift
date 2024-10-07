import SwiftUI

struct FollowersView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var followers: [String] = []
    @State private var isLoading = true
    var currentUserId: String

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Followers...")
                } else if followers.isEmpty {
                    Text("No followers yet.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    List(followers, id: \.self) { userId in
                        NavigationLink(destination: Text(userId)) { // Placeholder for UserDetailView
                            Text(userId) // Replace with user model to display username, etc.
                        }
                    }
                }
            }
            .navigationTitle("Followers")
        }
        .onAppear {
            fetchFollowers()
        }
    }

    private func fetchFollowers() {
        firebaseService.fetchFollowers(for: currentUserId) { followers in
            self.followers = followers
            self.isLoading = false
        }
    }
}

struct FollowersView_Previews: PreviewProvider {
    static var previews: some View {
        FollowersView(currentUserId: "sampleUserId").environmentObject(FirebaseService())
    }
}
