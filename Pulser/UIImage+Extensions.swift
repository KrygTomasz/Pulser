//
//  UIImage+Extensions.swift
//  Pulser
//
//  Created by Kryg Tomasz on 02.11.2017.
//  Copyright © 2017 Kryg Tomek. All rights reserved.
//

import UIKit
import AVFoundation

extension UIImage {
    func getColor(at position: CGPoint) -> UIColor {
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(position.y)) + Int(position.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
