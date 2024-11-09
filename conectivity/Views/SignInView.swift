import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Title or Logo
                Text("Connectify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .shadow(radius: 5)
                    .padding(.bottom, 20)


                // Email Field
                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.gray)
                    TextField("Enter your email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                // Password Field with Forgot Password Link below it
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.gray)
                    SecureField("Enter your password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    // Forgot Password Link
                    HStack {
                        Spacer()
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.black)
                        }
                    }
                }

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }

                // Sign In Button
                Button(action: {
                    firebaseService.signIn(email: email, password: password) { success, error in
                        if !success {
                            errorMessage = error?.localizedDescription ?? "Error"
                        }
                    }
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(10)
                }

                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

