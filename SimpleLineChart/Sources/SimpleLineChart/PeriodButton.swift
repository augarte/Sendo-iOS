//
//  File.swift
//  
//
//  Created by Aimar Ugarte on 9/10/22.
//

import Combine
import UIKit

@available(iOS 13.0, *)
@IBDesignable
public class PeriodButton: UIButton {
    
    private var color: UIColor?
    var period: (String, Int)?
    var cancellBag = Set<AnyCancellable>()
    
    init(period: (String, Int), color: UIColor, selectedPeriod: CurrentValueSubject<(String, Int)?,Never>, frame: CGRect) {
        super.init(frame: frame)
        self.period = period
        self.color = color
        setTitle(period.0, for: .normal)
        titleLabel?.textAlignment = .center
        backgroundColor =  .white.withAlphaComponent(0.1)
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = frame.height / 2
        titleLabel?.font = titleLabel?.font.withSize(12)
        selectedPeriod.sink{ selectedPeriod in
            guard let period = self.period, let selectedPeriod = selectedPeriod else { return }
            
            let selected = period == selectedPeriod
            self.backgroundColor = selected ? self.color?.withAlphaComponent(0.1) : .white.withAlphaComponent(0.1)
            self.layer.borderColor = selected ? self.color?.cgColor : UIColor.white.cgColor
        }.store(in: &cancellBag)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
