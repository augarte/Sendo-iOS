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
    @IBOutlet weak var changeLbl: UILabel!
    @IBOutlet weak var view: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func applyStyle() {
        selectionStyle = .none
        valueLbl.textColor = .white
        dateLbl.textColor = .white
    }
    
    func configureCell(entry: Measurement, change: Double) {
        valueLbl.text = entry.value.clean
        
        if let timestamp = Double(entry.date) {
            let date = Date(timeIntervalSince1970:timestamp)
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy"
            let dateString = formatter.string(from: date)
            dateLbl.text = dateString
        } else {
            dateLbl.text = ""
        }
        
        changeLbl.text = change == 0 ? "" : change.clean
        changeLbl.textColor = change > 0 ? .green : .red
        
        applyStyle()
    }
    
}
