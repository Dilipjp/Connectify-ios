//
//  conectivityApp.swift
//  conectivity
//
//  Created by Dilip on 2024-09-17.
//

import SwiftUI

import Firebase

@main
struct conectivityApp: App {
    @StateObject var firebaseService = FirebaseService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseService)
        }
    }
}
