//
//  SessionEditorViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/11/22.
//

import UIKit

class SessionEditorViewController: SendoViewController {
    
    private var completion: (() -> ())?
    
    static func create(completion: @escaping () -> ()) -> SessionEditorViewController {
        let sessionEditorVC = SessionEditorViewController(title: "Session")
        sessionEditorVC.completion = completion
        return sessionEditorVC
    }
}
