//
//  PeriodSelectorCell.swift
//  Sendo
//
//  Created by Aimar Ugarte on 11/6/22.
//

import UIKit

@IBDesignable class PeriodSelectorCell: UICollectionViewCell {
    
    @IBOutlet weak var button: UIButton!
    
    func applyStyle() {
        button.backgroundColor = .white
    }
    
    func configureCell(period: (String, Int)) {
        button.titleLabel?.text = period.0
        applyStyle()
    }

}
