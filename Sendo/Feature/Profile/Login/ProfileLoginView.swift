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
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size05
    }
    
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
    
    lazy var loginTitle: UILabel = {
        let title = UILabel()
        title.text = "Welcome"
        title.font = title.font.withSize(20)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    func setupView() {
        addSubviews([appleLoginButton, googleLoginButton, loginTitle])
        NSLayoutConstraint.activate([
            loginTitle.bottomAnchor.constraint(equalTo: appleLoginButton.topAnchor,
                                               constant: -Constants.margin),
            loginTitle.leadingAnchor.constraint(equalTo: appleLoginButton.leadingAnchor),
            appleLoginButton.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                    constant: Constants.margin),
            appleLoginButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                     constant: -Constants.margin),
            appleLoginButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            appleLoginButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            googleLoginButton.topAnchor.constraint(equalTo: appleLoginButton.bottomAnchor,
                                                    constant: Constants.margin),
            googleLoginButton.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                     constant: Constants.margin),
            googleLoginButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                      constant: -Constants.margin),
            googleLoginButton.heightAnchor.constraint(equalTo: appleLoginButton.heightAnchor),
            googleLoginButton.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
    
    @objc private func signinGooglePress(){
        tapLogginButtonSubject.send(.google)
    }
    
    @objc private func signinApplePress(){
        tapLogginButtonSubject.send(.apple)
    }
}
