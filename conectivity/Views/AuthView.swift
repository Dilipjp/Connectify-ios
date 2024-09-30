//
//  AuthView.swift
//  conectivity
//
//  Created by Dilip on 2024-09-29.
//

import Foundation
import SwiftUI

struct AuthView: View {
    @State private var showSignUp = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack {
                if showSignUp {
                    SignUpView(showSignUp: $showSignUp)
                        .environmentObject(authViewModel)
                } else {
                    SignInView(showSignUp: $showSignUp)
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
