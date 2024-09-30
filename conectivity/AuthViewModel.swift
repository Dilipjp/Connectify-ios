//
//  AuthViewModel.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import Foundation
import SwiftUI
import Firebase

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?

    init() {
        self.currentUser = Auth.auth().currentUser
    }

    var isSignedIn: Bool {
        return currentUser != nil
    }

    func signUp(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.currentUser = authResult?.user
            completion(.success(()))
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.currentUser = authResult?.user
            completion(.success(()))
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    func currentUserEmail() -> String? {
        return currentUser?.email
    }
}
