//
//  UIColorExtension.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/4/16.
//  Copyright © 2016 Adams. All rights reserved.
//
import UIKit

//Make color creation a bit easier.
extension UIColor {
    
    convenience init(r: Int, g: Int, b: Int, alpha: CGFloat = 1.0) {
        func intToColorFloat(int: Int) -> CGFloat {
            let divisor: CGFloat = 255
            return CGFloat(int) / divisor
        }
        
        self.init(red: intToColorFloat(r), green: intToColorFloat(g), blue: intToColorFloat(b), alpha: alpha)
    }
}
