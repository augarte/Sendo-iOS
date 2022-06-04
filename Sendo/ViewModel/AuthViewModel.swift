//
//  AuthViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 4/6/22.
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    
    var authUser = CurrentValueSubject<AuthUser?, Never>(nil)
    
    init() {
        
    }
    
}

extension AuthViewModel {

    func createUser(user: AuthUser) {
        FirebaseFirestoreServices.shared().createUser(authUser: user) { success in
            self.authUser.value = user
        }
    }

}
