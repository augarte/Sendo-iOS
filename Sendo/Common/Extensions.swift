//
//  Extensions.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation
import UIKit

extension NSObject {
    class var typeName: String {
        let name = String(describing: self)
        return name
    }
}

extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Float {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension UIColor {
    static func hexStringToUIColor(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    static let punkCellBackground = UIColor.hexStringToUIColor(hex:"#F5F5F5")
    static let punkPrimaryText = UIColor.hexStringToUIColor(hex: "#777777")
    static let punkSecondaryText = UIColor.hexStringToUIColor(hex: "#777777")
}

extension UIStackView {
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            self.removeArrangedSubview($0)
            NSLayoutConstraint.deactivate($0.constraints)
            $0.removeFromSuperview()
        }
    }
}

extension UIView {
    func addSubviews(_ subviews:[UIView]) {
        subviews.forEach  { self.customAddSubview($0) }
    }

    private func customAddSubview(_ view: UIView) {
        if let stack = self as? UIStackView {
            stack.addArrangedSubview(view)
        } else {
            self.addSubview(view)
        }
    }
}
