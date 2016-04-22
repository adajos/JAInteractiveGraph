//
//  CGExtensions.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/14/16.
//  Copyright © 2016 adams. All rights reserved.
//

import UIKit

extension CGContext {
    func performContextSafeDrawing(drawStuff: Void -> Void) {
        CGContextSaveGState(self)
        drawStuff()
        CGContextRestoreGState(self)
    }
}
