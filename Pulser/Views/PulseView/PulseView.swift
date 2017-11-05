//
//  PulseView.swift
//  Pulser
//
//  Created by Kryg Tomasz on 02.11.2017.
//  Copyright © 2017 Kryg Tomek. All rights reserved.
//

import UIKit

class PulseView: UIView {
    
    @IBOutlet weak private var heartImageView: UIImageView! {
        didSet {
            heartImageView.image = #imageLiteral(resourceName: "heart")
        }
    }
    @IBOutlet weak private var heartHeight: NSLayoutConstraint! {
        didSet {
            maxHeartHeight = heartHeight.constant
        }
    }
    @IBOutlet weak private var pulseLabel: UILabel! {
        didSet {
            pulseLabel.textColor = .white
        }
    }
    
    var valuesArray: [CGFloat] = []
    var lineSize: CGFloat = 3.0
    var lineColor: UIColor = .black
    var isMeasuring: Bool = false {
        didSet {
            if isMeasuring {
                
            }
            else {
                resetMeasurement()
            }
        }
    }
    private var contentView : UIView!
    private var timer: Timer?
    private var isTimerOn: Bool = false
    private var maxHeartHeight: CGFloat = 0.0
    private var minimumsArray: [CGFloat] = []
    private var newValueWasBelowAverage: Bool = false
    private var width: CGFloat = 0.0
    private var height: CGFloat = 0.0
    private(set) var currentMinimum: CGFloat = 0.0
    private(set) var currentMaximum: CGFloat = 0.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        height = self.bounds.height
        width = self.bounds.width
        xibSetup()
    }
    
    @objc func finishMeasurement() {
        pulseLabel.text = "\(minimumsArray.count*6)"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    func xibSetup() {
        contentView = loadViewFromNib()
        contentView.frame = bounds
        contentView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(contentView)
    }
    
    private func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
}

//MARK: Measure handling
extension PulseView {
    
    private func resetMeasurement() {
        valuesArray.removeAll()
        minimumsArray.removeAll()
        newValueWasBelowAverage = false
        stopTimer()
    }
    
    func addNewPulseValue(_ newValue: CGFloat) {
        valuesArray.append(newValue)
        tryToReduceValuesQuantity()
        tryToDetectHeartBeat(using: newValue)
    }
    
    private func tryToReduceValuesQuantity() {
        while valuesArray.count > Int(width/lineSize) {
            valuesArray.remove(at: 0)
        }
    }
    
    private func tryToDetectHeartBeat(using newValue: CGFloat) {
        if valuesArray.count > 2 {
            let average = (currentMaximum + currentMinimum)/2
            if newValue > average && newValueWasBelowAverage {
                newValueWasBelowAverage = false
            }
            if newValue < average && !newValueWasBelowAverage {
                newValueWasBelowAverage = true
                minimumsArray.append(newValue)
                print("Detected heart beat")
                pulseLabel.text = "Measuring..."
                tryToStartTimer()
            }
        }
    }
    
    private func tryToStartTimer() {
        if isTimerOn { return }
        else {
            timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(finishMeasurement), userInfo: nil, repeats: true)
            isTimerOn = true
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        isTimerOn = false
    }
    
}

// MARK: Drawing
extension PulseView {
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(lineSize)
        context.setStrokeColor(lineColor.cgColor)
        connectPoints(context)
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
        let lastY = scaleYValue(lastValue, minimum: currentMinimum, maximum: currentMaximum, forHeight: height)
        let point = CGPoint(x: lineSize*CGFloat(lastIndex), y: lastY)
        let rect = CGRect(x: point.x-1.5*lineSize, y: point.y-1.5*lineSize, width: 3*lineSize, height: 3*lineSize)
        context.fillEllipse(in: rect)
    }
    
    private func drawLine(_ context: CGContext) {
        context.beginPath()
        let firstValue = valuesArray[0]
        let firstY = scaleYValue(firstValue, minimum: currentMinimum, maximum: currentMaximum, forHeight: height)
        let startPoint = CGPoint(x: CGFloat(0), y: firstY)
        context.move(to: startPoint)
        for i in 1..<valuesArray.count {
            let value = valuesArray[i]
            let y = scaleYValue(value, minimum: currentMinimum, maximum: currentMaximum, forHeight: height)
            let point = CGPoint(x: lineSize*CGFloat(i), y: y)
            context.addLine(to: point)
            rescaleHeart(value)
        }
    }
    
    private func rescaleHeart(_ value: CGFloat) {
        let minimumSizePercent: CGFloat = 0.5
        let maximumSizePercent: CGFloat = 1.0
        let percentValue = getValuePercent(value, minimum: currentMinimum, maximum: currentMaximum)
        let rescaledPercent = percentValue * (maximumSizePercent - minimumSizePercent) + minimumSizePercent
        let newHeight = rescaledPercent * maxHeartHeight
        heartHeight.constant = newHeight
    }
    
    func redraw() {
        self.setNeedsDisplay()
    }
    
}

// MARK: Value scaling
extension PulseView {
    
    private func getValuePercent(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        let scaledY = (value - minimum) * (1/(maximum-minimum))
        return scaledY
    }
    
    private func scaleYValue(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat, forHeight height: CGFloat) -> CGFloat {
        var scaledValue = getValuePercent(value, minimum: minimum, maximum: maximum) * height
        let scale: CGFloat = 0.95
        scaledValue = scaledValue * scale + (1.0 - scale) * height / 2
        return scaledValue
    }
    
}
