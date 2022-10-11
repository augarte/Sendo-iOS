//
//  SimpleLineChart.swift
//  Sendo
//
//  Created by Aimar Ugarte on 29/5/22.
//

import Combine
import UIKit

private enum Constants {
    static let cornerRadiusSize = CGSize(width: 8.0, height: 8.0)
    static let margin: CGFloat = 20.0
    static let topBorder: CGFloat = 20.0
    static let colorAlpha: CGFloat = 0.3
    static let circleDiameter: CGFloat = 5.0
    static let periodSpacing: CGFloat = 5.0
    static let periodBottomSpace: CGFloat = 10.0
    static let periodButtonHeight: CGFloat = 30.0
    static let bottomBorder: CGFloat = Constants.periodButtonHeight + Constants.periodBottomSpace + Constants.margin
}

@available(iOS 13.0, *)
@IBDesignable
public class SimpleLineChart: UIView {
    
    @IBInspectable var lineStroke: Double = 3.0
    
    @IBInspectable var lineShadowGradient: Bool = true
    @IBInspectable var lineShadowgradientStart: UIColor = UIColor.hexStringToUIColor(hex: "FEB775")
    @IBInspectable var lineShadowgradientEnd: UIColor = UIColor.hexStringToUIColor(hex: "FEB775")
    
    @IBInspectable var backgroundGradient: Bool = true
    @IBInspectable var gradientStartColor: UIColor = UIColor.hexStringToUIColor(hex: "FEB775")
    @IBInspectable var gradientEndColor: UIColor = UIColor.hexStringToUIColor(hex: "FD4345")
    
    lazy var stackView: UIStackView = {
        let stackview = UIStackView()
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.axis = .horizontal
        stackview.distribution = .fillEqually
        stackview.spacing = Constants.periodSpacing
        return stackview
    }()
    
    var periodSelectors: Array<(String, Int)> = [("1 Month", 2629800), ("3 Month", 7889400), ("1 Year", 31557600), ("All Time", 3155760000)]
    var selectedPeriod = CurrentValueSubject<(String, Int)?, Never>((String, Int)?(nil))
    var graphPoints: Array<(Int, Double)> = []
    var filteredGraphPoints: Array<(Int, Double)> = []
    
    public override func draw(_ rect: CGRect) {
        let width = rect.width
        let height = rect.height
        
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: .allCorners,
            cornerRadii: Constants.cornerRadiusSize
        )
        path.addClip()
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // -------------------
        // Gradient setup
        let colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: colorLocations
        ) else { return }
        
        // -------------------
        // Background gradient
        if (backgroundGradient) {
            let startPoint = CGPoint.zero
            let endPoint = CGPoint(x: 0, y: bounds.height)
            context.drawLinearGradient(
                gradient,
                start: startPoint,
                end: endPoint,
                options: []
            )
        }
        
        // -------------------
        // Margins
        let margin = Constants.margin
        let graphWidth = width - margin * 2 - 4
        let xValues = filteredGraphPoints.map({ point in return point.0 })
        guard let minXValue = xValues.min() else { return }
        guard let maxXValue = xValues.max() else { return }
        let columnXPoint = { (column: Int) -> CGFloat in
            // Calculate the gap between points
            guard self.filteredGraphPoints.count > 1 else {
                return CGFloat(graphWidth/2) + margin + 2
            }
            let xPoint = CGFloat(column-minXValue) / CGFloat(maxXValue-minXValue) * graphWidth
            return CGFloat(xPoint) + margin + 2
        }
        
        let topBorder = Constants.topBorder
        let bottomBorder = Constants.bottomBorder
        let graphHeight = height - topBorder - bottomBorder
        let yValues = filteredGraphPoints.map({ point in return point.1 })
        guard let minYValue = yValues.min() else { return }
        guard let maxYValue = yValues.max() else { return }
        let columnYPoint = { (graphPoint: Double) -> CGFloat in
            guard self.filteredGraphPoints.count > 1 else {
                return graphHeight + topBorder - (graphHeight/2)
            }
            let yPoint = CGFloat(graphPoint-minYValue) / CGFloat(maxYValue-minYValue) * graphHeight
            return graphHeight + topBorder - yPoint // Flip the graph
        }
        
        // -------------------
        // Stroke
        UIColor.white.setFill()
        UIColor.white.setStroke()
        
        let graphPath = UIBezierPath()
        graphPath.move(to: CGPoint(x: columnXPoint(filteredGraphPoints[0].0), y: columnYPoint(filteredGraphPoints[0].1)))
        
        // Add points for each item in the filteredGraphPoints array
        // at the correct (x, y) for the point
        for i in 1..<filteredGraphPoints.count {
            let nextPoint = CGPoint(x: columnXPoint(filteredGraphPoints[i].0), y: columnYPoint(filteredGraphPoints[i].1))
            graphPath.addLine(to: nextPoint)
        }
        
        context.saveGState()
        
        // -------------------
        // Line shadow gradient
        if (lineShadowGradient) {
            guard let clippingPath = graphPath.copy() as? UIBezierPath else {
                return
            }
            
            clippingPath.addLine(to: CGPoint(
                x: columnXPoint(filteredGraphPoints[filteredGraphPoints.count - 1].0),
                y: height))
            clippingPath.addLine(to: CGPoint(x: columnXPoint(filteredGraphPoints[0].0), y: height))
            clippingPath.close()
            clippingPath.addClip()
            
            let highestYPoint = columnYPoint(maxYValue)
            let graphStartPoint = CGPoint(x: margin, y: highestYPoint)
            let graphEndPoint = CGPoint(x: margin, y: bounds.height)
            
            context.drawLinearGradient(
                gradient,
                start: graphStartPoint,
                end: graphEndPoint,
                options: [])
        }
        context.restoreGState()
        
        graphPath.lineWidth = lineStroke
        graphPath.stroke()
        
        // -------------------
        // Data points
        for i in 0..<filteredGraphPoints.count {
            var point = CGPoint(x: columnXPoint(filteredGraphPoints[i].0), y: columnYPoint(filteredGraphPoints[i].1))
            point.x -= Constants.circleDiameter / 2
            point.y -= Constants.circleDiameter / 2
            
            let circle = UIBezierPath(
                ovalIn: CGRect(
                    origin: point,
                    size: CGSize(
                        width: Constants.circleDiameter,
                        height: Constants.circleDiameter)
                )
            )
            circle.fill()
        }
        
        // -------------------
        // Date selectors
        addStackView(width: width, height: height)
    }
}

extension SimpleLineChart {
    
    func addStackView(width: Double, height: Double) {
        guard !stackView.isDescendant(of: self) else { return }
                
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: Constants.periodButtonHeight),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                              constant: Constants.margin),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                               constant: -Constants.margin),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                           constant: -Constants.periodBottomSpace)
        ])
        addPeriodSelectors(width: width, height: height)
    }
    
    func addPeriodSelectors(width: Double, height: Double) {
        stackView.removeAllArrangedSubviews()
        let buttonWidth = ((width - (Constants.margin * Double(periodSelectors.count+1))) / Double(periodSelectors.count))

        for (i, period) in periodSelectors.enumerated() {
            let isSelected = selectedPeriod.value == nil ? i == 0 : selectedPeriod.value! == period
            let separation = i != 0 ? Constants.margin : 0
            let frame = CGRect(x: Constants.margin + (separation + buttonWidth) * Double(i),
                               y: 0,
                               width: buttonWidth,
                               height: Constants.periodButtonHeight)
            let button = PeriodButton(period: period, color:gradientStartColor, selectedPeriod: selectedPeriod, frame: frame)
            button.addTarget(self, action: #selector(dateButtonPress), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        
        if selectedPeriod.value == nil, let period = periodSelectors.first {
            changeDateRange(period: period)
        }
    }
    
    @objc func dateButtonPress(sender: PeriodButton) {
        guard let period = sender.period else { return }
        selectedPeriod.send(period)
        changeDateRange(period: period)
    }
    
    private func changeDateRange(period: (String, Int)) {
        let timestamp = Int(NSDate().timeIntervalSince1970)
        selectedPeriod.value = period
        filteredGraphPoints = graphPoints.filter({ value in
            return value.0 > timestamp - (selectedPeriod.value?.1 ?? timestamp)
        })
        self.setNeedsDisplay()
    }
    
    public func setPoints(points: Array<(Int, Double)>) {
        graphPoints = points
        filteredGraphPoints = graphPoints
        self.setNeedsDisplay()
    }
}
