//
//  SimpleLineChart.swift
//  Sendo
//
//  Created by Aimar Ugarte on 29/5/22.
//

import UIKit

private enum Constants {
    static let cornerRadiusSize = CGSize(width: 8.0, height: 8.0)
    static let margin: CGFloat = 20.0
    static let topBorder: CGFloat = 60
    static let bottomBorder: CGFloat = 50
    static let colorAlpha: CGFloat = 0.3
    static let circleDiameter: CGFloat = 5.0
}

@IBDesignable
class SimpleLineChart: UIView {
    
    @IBInspectable var lineStroke: Double = 3.0
    
    @IBInspectable var lineShadowGradient: Bool = true
    @IBInspectable var lineShadowgradientStart: UIColor = UIColor.hexStringToUIColor(hex: "FEB775")
    @IBInspectable var lineShadowgradientEnd: UIColor = UIColor.hexStringToUIColor(hex: "FEB775")
  
    @IBInspectable var backgroundGradient: Bool = true
    @IBInspectable var gradientStartColor: UIColor = UIColor.hexStringToUIColor(hex: "FEB775")
    @IBInspectable var gradientEndColor: UIColor = UIColor.hexStringToUIColor(hex: "FD4345")
    
    var graphPoints: Array<(Int, Double)> = []

    override func draw(_ rect: CGRect) {
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
        let xValues = graphPoints.map({ point in return point.0 })
        guard let minXValue = xValues.min() else { return }
        guard let maxXValue = xValues.max() else { return }
        let columnXPoint = { (column: Int) -> CGFloat in
            // Calculate the gap between points
            guard self.graphPoints.count > 1 else {
                return CGFloat(graphWidth/2) + margin + 2
            }
            let xPoint = CGFloat(column-minXValue) / CGFloat(maxXValue-minXValue) * graphWidth
            return CGFloat(xPoint) + margin + 2
        }
        
        let topBorder = Constants.topBorder
        let bottomBorder = Constants.bottomBorder
        let graphHeight = height - topBorder - bottomBorder
        let yValues = graphPoints.map({ point in return point.1 })
        guard let minYValue = yValues.min() else { return }
        guard let maxYValue = yValues.max() else { return }
        let columnYPoint = { (graphPoint: Double) -> CGFloat in
            guard self.graphPoints.count > 1 else {
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
        graphPath.move(to: CGPoint(x: columnXPoint(graphPoints[0].0), y: columnYPoint(graphPoints[0].1)))
            
        // Add points for each item in the graphPoints array
        // at the correct (x, y) for the point
        for i in 1..<graphPoints.count {
            let nextPoint = CGPoint(x: columnXPoint(graphPoints[i].0), y: columnYPoint(graphPoints[i].1))
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
                x: columnXPoint(graphPoints[graphPoints.count - 1].0),
                y: height))
            clippingPath.addLine(to: CGPoint(x: columnXPoint(graphPoints[0].0), y: height))
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
        for i in 0..<graphPoints.count {
            var point = CGPoint(x: columnXPoint(graphPoints[i].0), y: columnYPoint(graphPoints[i].1))
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
    }
    
    open func setPoints(points: Array<(Int, Double)>) {
        graphPoints = points
        self.setNeedsDisplay()
    }
}
