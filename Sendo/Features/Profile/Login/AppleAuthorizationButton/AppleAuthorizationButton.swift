//
//  AppleAuthorizationButton.swift
//  Sendo
//
//  Created by Aimar Ugarte on 28/5/22.
//

import UIKit
import AuthenticationServices

@IBDesignable
class AppleAuthorizationButton: UIButton {

    private var authorizationButton: ASAuthorizationAppleIDButton!
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        authorizationButton = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .black)
        addSubview(authorizationButton)

        authorizationButton.addTarget(self, action: #selector(authorizationAppleIDButtonTapped(_:)), for: .touchUpInside)

        authorizationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            authorizationButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0),
            authorizationButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0.0),
            authorizationButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.0),
            authorizationButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0),
        ])
    }
    
    @objc func authorizationAppleIDButtonTapped(_ sender: Any) {
        // Forward the touch up inside event to MyAuthorizationAppleIDButton
        sendActions(for: .touchUpInside)
    }
    
}
