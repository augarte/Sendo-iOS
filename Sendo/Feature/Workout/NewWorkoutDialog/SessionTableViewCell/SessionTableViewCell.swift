//
//  SessionTableViewCell.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/11/22.
//

import UIKit

class SessionTableViewCell: UITableViewCell {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size03
        static let imageHeight: CGFloat = 56
        static let aspectRatio: CGFloat = 1.5
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension SessionTableViewCell {
    
    func configureCell() {
    }
}
