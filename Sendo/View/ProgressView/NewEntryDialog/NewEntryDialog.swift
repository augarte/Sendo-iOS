//
//  NewEntryDialog.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/6/22.
//

import UIKit

class NewEntryDialog: SendoViewController {
    
    @IBOutlet weak var navigationTitle: UINavigationItem!
    @IBOutlet weak var cancelBtn: UIBarButtonItem!
    @IBOutlet weak var addBtn: UIBarButtonItem!
        
    @IBOutlet weak var labelsView: UIView!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelValue: UILabel!
    
    weak var delegate: ProgressViewControllerDelegate?
    let dataType = "Weight"
    
    static func create() -> NewEntryDialog {
        return NewEntryDialog(title: "New Entry", nibName: NewEntryDialog.typeName)
    }
    
    override func viewDidLoad(){
        labelDate.text = "Date"
        labelValue.text = "Value"
        labelsView.backgroundColor = .white.withAlphaComponent(0.2)
        labelsView.layer.cornerRadius = 8
        addToolbar()
    }
    
    // MARK: - Toolbar
    func addToolbar(){
        navigationTitle.title = dataType
        cancelBtn.title = "Cancel"
        addBtn.title = "Add"
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func addEntry(_ sender: Any) {
        if let delegate = delegate {
            let timestamp = String(Int(NSDate().timeIntervalSince1970))
            let newEntry = Measurement(date: timestamp, value: 93.0)
            delegate.didAddNewEntry(newEntry: newEntry)
        }
        dismiss(animated: true)
    }

}
