//
//  NewEntryDialog.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/6/22.
//

import UIKit

class NewEntryDialog: SendoViewController {
        
    @IBOutlet weak var labelsView: UIView!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelValue: UILabel!
    
    static func create() -> NewEntryDialog {
        return NewEntryDialog(title: "New Entry", nibName: NewEntryDialog.typeName)
    }
    
    override func viewDidLoad(){
        labelDate.text = "Date"
        labelValue.text = "Value"
        labelsView.backgroundColor = .white.withAlphaComponent(0.2)
        labelsView.layer.cornerRadius = 5

    }

}
