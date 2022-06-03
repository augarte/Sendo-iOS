//
//  ProgressTableCell.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/6/22.
//

import UIKit

class ProgressTableCell: UITableViewCell {
    
    @IBOutlet weak var valueLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
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
        valueLbl.text = String(format: "%.2f", entry.value)
        
        if let timestamp = Double(entry.date) {
            let date = Date(timeIntervalSince1970:timestamp)
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd MMMM yyyy"
            let dateString = formatter.string(from: date)
            dateLbl.text = dateString
        } else {
            dateLbl.text = ""
        }
    }
    
}
