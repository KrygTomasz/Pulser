//
//  Pixel.swift
//  Pulser
//
//  Created by Kryg Tomasz on 02.11.2017.
//  Copyright © 2017 Kryg Tomek. All rights reserved.
//

import UIKit

class Pixel {
    private var point: CGPoint?
    private(set) var red: CGFloat?
    private(set) var green: CGFloat?
    private(set) var blue: CGFloat?
    private(set) var alpha: CGFloat?
    
    var brightness: CGFloat {
        get {
            guard
                let redFloat = red,
                let greenFloat = green,
                let blueFloat = blue else {
                    return 0
            }
            return (redFloat+greenFloat+blueFloat)/3.0
        }
    }
    
    init(of image: UIImage?, at point: CGPoint?) {
        self.point = point
        guard let pointObject = point else { return }
        let color = image?.getColor(at: pointObject)
        setRGB(using: color)
    }
    
    private func setRGB(using color: UIColor?) {
        guard let color = color else { return }
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if color.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            self.red = fRed
            self.green = fGreen
            self.blue = fBlue
            self.alpha = fAlpha
        } else {
            print("Could not extract RGBA components")
        }
    }
}
