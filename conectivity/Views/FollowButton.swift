import SwiftUI

struct FollowButton: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var currentUserId: String
    var userIdToFollow: String
    @State private var isFollowing: Bool = false
    @State private var isLoading: Bool = false

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            isLoading = true
            if isFollowing {
                unfollowUser()
            } else {
                followUser()
            }
        }) {
            Text(isFollowing ? "Unfollow" : "Follow")
                .foregroundColor(.white)
                .padding()
                .background(isFollowing ? Color.red : Color.blue)
                .cornerRadius(8)
                .opacity(isLoading ? 0.5 : 1)
        }
        .onAppear {
            checkFollowingStatus()
        }
    }

    private func followUser() {
        firebaseService.followUser(currentUserId: currentUserId, userIdToFollow: userIdToFollow) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isFollowing = true
                } else {
                    print("Error following user: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    private func unfollowUser() {
        firebaseService.unfollowUser(currentUserId: currentUserId, userIdToUnfollow: userIdToFollow) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isFollowing = false
                } else {
                    print("Error unfollowing user: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    private func checkFollowingStatus() {
        firebaseService.checkFollowingStatus(currentUserId: currentUserId, userIdToFollow: userIdToFollow) { following, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking following status: \(error.localizedDescription)")
                } else {
                    isFollowing = following
                }
            }
        }
    }
}
