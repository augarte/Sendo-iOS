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
        addSubview(valueLbl)
        addSubview(changeLbl)
        addSubview(dateLbl)
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
        valueLbl.textColor = .white
        dateLbl.textColor = .white
    }
}

extension ProgressTableCell {
    
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
        
        changeLbl.text = change == 0 ? "" : "\(change.clean)%"
        changeLbl.textColor = change > 0 ? .systemGreen : .systemRed
        
        applyStyle()
    }
}
