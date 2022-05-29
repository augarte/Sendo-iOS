//
//  BaseTabViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 30/5/22.
//

import UIKit

open class BaseTabViewController: SendoViewController {
    
    final let tabImage: String
        
    init(title: String, image: String, nibName: String) {
        tabImage = image
        super.init(title: title, nibName: nibName)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
