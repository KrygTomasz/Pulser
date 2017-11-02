//
//  PulseView.swift
//  Pulser
//
//  Created by Kryg Tomasz on 02.11.2017.
//  Copyright © 2017 Kryg Tomek. All rights reserved.
//

import UIKit

class PulseView: UIView {
    
    var valuesArray: [CGFloat] = []
    var lineSize: CGFloat = 3.0
    var lineColor: UIColor = .black
    private var width: CGFloat = 0.0
    private var height: CGFloat = 0.0
    private(set) var currentMinimum: CGFloat = 0.0
    private(set) var currentMaximum: CGFloat = 0.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        height = self.bounds.height
        width = self.bounds.width
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func redraw() {
        tryToReduceValuesQuantity()
        self.setNeedsDisplay()
    }
    
    private func tryToReduceValuesQuantity() {
        while valuesArray.count > Int(width/lineSize) {
            valuesArray.remove(at: 0)
        }
    }
    
    private func connectPoints(_ context: CGContext) {
        if valuesArray.isEmpty { return }
        currentMinimum = valuesArray.min() ?? 0.0
        currentMaximum = valuesArray.max() ?? 0.0
        drawPulse(context)
    }
    
    private func drawPulse(_ context: CGContext) {
        drawCursor(context)
        drawLine(context)
        context.setLineJoin(.round)
        context.strokePath()
    }
    
    private func drawCursor(_ context: CGContext) {
        let lastIndex = valuesArray.count - 1
        let lastValue = valuesArray[lastIndex]
        let lastY = scaleYValue(lastValue, minimum: currentMinimum, maximum: currentMaximum)
        let point = CGPoint(x: lineSize*CGFloat(lastIndex), y: lastY)
        let rect = CGRect(x: point.x-1.5*lineSize, y: point.y-1.5*lineSize, width: 3*lineSize, height: 3*lineSize)
        context.fillEllipse(in: rect)
    }
    
    private func drawLine(_ context: CGContext) {
        context.beginPath()
        let firstValue = valuesArray[0]
        let firstY = scaleYValue(firstValue, minimum: currentMinimum, maximum: currentMaximum)
        let startPoint = CGPoint(x: CGFloat(0), y: firstY)
        context.move(to: startPoint)
        for i in 1..<valuesArray.count {
            let value = valuesArray[i]
            let y = scaleYValue(value, minimum: currentMinimum, maximum: currentMaximum)
            let point = CGPoint(x: lineSize*CGFloat(i), y: y)
            context.addLine(to: point)
        }
    }
    
    private func scaleYValue(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        var scaledY = (value - minimum) * (height/(maximum-minimum))
        let scale: CGFloat = 0.95
        scaledY = scaledY * scale + (1.0 - scale) * height / 2
        return scaledY
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(lineSize)
        context?.setStrokeColor(lineColor.cgColor)
        connectPoints(context!)
    }
    
}
