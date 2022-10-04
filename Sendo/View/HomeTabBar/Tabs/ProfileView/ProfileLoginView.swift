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
    
    var buttonPressedSubject = PassthroughSubject<LoginType, Never>()
    
    lazy var appleLogginButton: AppleAuthorizationButton = {
        let button = AppleAuthorizationButton.init()
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (signinApplePress))
        button.addGestureRecognizer(gesture)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var googleLogginButton: GIDSignInButton = {
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
        addSubview(appleLogginButton)
        addSubview(googleLogginButton)
        addSubview(loginTitle)
        NSLayoutConstraint.activate([
            loginTitle.bottomAnchor.constraint(equalTo: appleLogginButton.topAnchor,
                                               constant: -Constants.margin),
            loginTitle.leftAnchor.constraint(equalTo: appleLogginButton.leftAnchor),
            appleLogginButton.leftAnchor.constraint(equalTo: leftAnchor,
                                                    constant: Constants.margin),
            appleLogginButton.rightAnchor.constraint(equalTo: rightAnchor,
                                                     constant: -Constants.margin),
            appleLogginButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            appleLogginButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            googleLogginButton.topAnchor.constraint(equalTo: appleLogginButton.bottomAnchor,
                                                    constant: Constants.margin),
            googleLogginButton.leftAnchor.constraint(equalTo: leftAnchor,
                                                     constant: Constants.margin),
            googleLogginButton.rightAnchor.constraint(equalTo: rightAnchor,
                                                      constant: -Constants.margin),
            googleLogginButton.heightAnchor.constraint(equalTo: appleLogginButton.heightAnchor),
            googleLogginButton.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
    
    @objc private func signinGooglePress(){
        buttonPressedSubject.send(.google)
    }
    
    @objc private func signinApplePress(){
        buttonPressedSubject.send(.apple)
    }
}
