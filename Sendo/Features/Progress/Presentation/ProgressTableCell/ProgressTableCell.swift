//
//  ProgressTableCell.swift
//  Sendo
//
//  Created by Aimar Ugarte on 3/6/22.
//

import UIKit

class ProgressTableCell: UITableViewCell {
    
    private enum Constants {
        static let margin: CGFloat = Spacer.size04
        static let topMargin: CGFloat = Spacer.size02
    }

    private lazy var valueLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var changeLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var dateLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadView()
        applyStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func loadView() {
        addSubviews([valueLbl, changeLbl, dateLbl])
        NSLayoutConstraint.activate([
            valueLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.margin),
            valueLbl.topAnchor.constraint(equalTo: topAnchor, constant: Constants.margin),
            changeLbl.topAnchor.constraint(equalTo: valueLbl.bottomAnchor, constant: Constants.topMargin),
            dateLbl.leadingAnchor.constraint(greaterThanOrEqualTo: valueLbl.trailingAnchor, constant: Constants.margin),
            
            changeLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.margin),
            bottomAnchor.constraint(equalTo: changeLbl.bottomAnchor, constant: Constants.margin),
            dateLbl.leadingAnchor.constraint(greaterThanOrEqualTo: changeLbl.trailingAnchor, constant: Constants.margin),
            
            trailingAnchor.constraint(equalTo: dateLbl.trailingAnchor, constant: Constants.margin),
            dateLbl.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func applyStyle() {
        backgroundColor = .clear
        selectionStyle = .none
        valueLbl.textColor = .label
        dateLbl.textColor = .label
    }
}

extension ProgressTableCell {
    
    func configureCell(entry: BodyMeasurement, change: Double) {
        valueLbl.text = entry.value.clean
        
        dateLbl.text = entry.measuredAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())

        changeLbl.text = change == 0 ? "" : "\(change.clean)%"
        changeLbl.textColor = change > 0 ? .systemGreen : .systemRed
        
        applyStyle()
    }
}
