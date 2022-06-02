//
//  ProgressTableCell.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/6/22.
//

import UIKit

class ProgressTableCell: UITableViewCell {
    
    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var view: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func applyStyle() {
        
    }
    
    func configureCell(entry: Measurement) {
        value.text = String(format: "%.2f", entry.value)
    }
    
}
