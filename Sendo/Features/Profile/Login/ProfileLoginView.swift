//
//  ProfileLoginView.swift
//  Sendo
//
//  Created by Aimar Ugarte on 2/10/22.
//

import Foundation
import UIKit
import Firebase
import GoogleSignIn
import Combine

class ProfileLoginView: UIView {
    
    enum LoginType {
        case google
        case apple
    }
    
    var tapLogginButtonSubject = PassthroughSubject<LoginType, Never>()
    
    lazy var appleLoginButton: AppleAuthorizationButton = {
        let button = AppleAuthorizationButton.init()
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (signinApplePress))
        button.addGestureRecognizer(gesture)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (signinGooglePress))
        button.addGestureRecognizer(gesture)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    func setupView() {
        let providers = UIStackView(arrangedSubviews: [appleLoginButton, googleLoginButton])
        providers.axis = .vertical
        providers.distribution = .fillEqually
        providers.spacing = 8
        providers.translatesAutoresizingMaskIntoConstraints = false
        addSubview(providers)
        NSLayoutConstraint.activate([
            providers.topAnchor.constraint(equalTo: topAnchor),
            providers.bottomAnchor.constraint(equalTo: bottomAnchor),
            providers.leadingAnchor.constraint(equalTo: leadingAnchor),
            providers.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @objc private func signinGooglePress(){
        tapLogginButtonSubject.send(.google)
    }
    
    @objc private func signinApplePress(){
        tapLogginButtonSubject.send(.apple)
    }
}
