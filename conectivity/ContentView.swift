//
//  ContentView.swift
//  conectivity
//
//  Created by Dilip on 2024-09-17.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        Group {
            if firebaseService.isLoggedIn {
                HomeView() // User is logged in, navigate to Home
            } else {
                SignInView() // User is not logged in, navigate to Sign-In
            }
        }
        .onAppear {
            checkAuthStatus()
        }
    }

    // Function to check the authentication status and redirect accordingly
    func checkAuthStatus() {
        firebaseService.isLoggedIn = Auth.auth().currentUser != nil
    }
}
