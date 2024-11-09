//
//  ForgotPasswordView.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var isSuccessMessageShown = false
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        VStack(spacing: 20) {
            Text("Forgot Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 30)
            
            Image("logo") 
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                .shadow(radius: 5)
                .padding(.bottom, 20)


            Text("Enter your email to receive a password reset link.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
                .background(Color(.white))

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 40)

            Button(action: {
                firebaseService.sendPasswordReset(email: email) { success, error in
                    if success {
                        isSuccessMessageShown = true
                        errorMessage = ""
                    } else {
                        errorMessage = error?.localizedDescription ?? "An error occurred"
                    }
                }
            }) {
                Text("Send Password Reset")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 40)
            }

            if isSuccessMessageShown {
                Text("A reset link has been sent to your email.")
                    .foregroundColor(.green)
                    .font(.subheadline)
                    .padding(.top, 10)
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.top, 10)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .onTapGesture {
            // Dismiss keyboard when tapping outside the text field
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

