//
//  PasswordResetView.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//


import SwiftUI
import Firebase

struct PasswordResetView: View {
    @Binding var resetEmail: String
    @Binding var resetErrorMessage: String
    @Binding var showPasswordReset: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white, Color.yellow]), startPoint: .topLeading, endPoint: .bottomLeading)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("app_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .padding()
                    .clipShape(Circle())
                Text("Reset Password")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Email", text: $resetEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if !resetErrorMessage.isEmpty {
                    Text(resetErrorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    sendPasswordReset()
                }) {
                    Text("Send Reset Link")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .padding()
                        .frame(width: 200, height: 50)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    showPasswordReset = false
                }) {
                    Text("Back to Sign In")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .padding()
            }
            .padding()
        }
    }
        
        func sendPasswordReset() {
            Auth.auth().sendPasswordReset(withEmail: resetEmail) { error in
                if let error = error {
                    resetErrorMessage = error.localizedDescription
                } else {
                    resetErrorMessage = "A password reset link has been sent to your email."
                }
            }
        }
    
}

struct PasswordResetView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordResetView(resetEmail: .constant(""), resetErrorMessage: .constant(""), showPasswordReset: .constant(false))
    }
}
