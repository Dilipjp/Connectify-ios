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
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Send Password Reset") {
                firebaseService.sendPasswordReset(email: email) { success, error in
                    if !success {
                        errorMessage = error?.localizedDescription ?? "Error"
                    }
                }
            }

            Text(errorMessage)
                .foregroundColor(.red)
        }
        .padding()
    }
}

