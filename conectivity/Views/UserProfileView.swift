import SwiftUI
import Firebase
import FirebaseAuth

struct UserProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var userId: String
    @State private var user: UserData?
    @State private var isFollowing: Bool = false

    var body: some View {
        VStack {
            if let userData = user {
                // User Profile Image
                Image(uiImage: userData.profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .padding()

                Text(userData.userName)
                    .font(.largeTitle)
                    .padding()

                // Follow/Unfollow button
                Button(action: {
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
                }
                .padding()
            } else {
                ProgressView("Loading User...")
            }
        }
        .onAppear {
            fetchUserData()
            checkFollowingStatus()
        }
    }

    private func fetchUserData() {
        let dbRef = Database.database().reference()
        dbRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            if let userDict = snapshot.value as? [String: Any],
               let userName = userDict["userName"] as? String,
               let userProfileImage = userDict["userProfileImage"] as? String,
               let imageUrl = URL(string: userProfileImage) {
                
                URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.user = UserData(userName: userName, profileImage: image)
                        }
                    }
                }.resume()
            }
        }
    }

    private func followUser() {
        firebaseService.followUser(currentUserId: Auth.auth().currentUser?.uid ?? "", userIdToFollow: userId) { success, error in
            if success {
                DispatchQueue.main.async {
                    isFollowing = true
                }
            }
        }
    }

    private func unfollowUser() {
        firebaseService.unfollowUser(currentUserId: Auth.auth().currentUser?.uid ?? "", userIdToUnfollow: userId) { success, error in
            if success {
                DispatchQueue.main.async {
                    isFollowing = false
                }
            }
        }
    }

    private func checkFollowingStatus() {
        firebaseService.checkFollowingStatus(currentUserId: Auth.auth().currentUser?.uid ?? "",
                                             userIdToFollow: userId) { isFollowing, error in
            DispatchQueue.main.async {
                self.isFollowing = isFollowing
            }
        }
    }
}
