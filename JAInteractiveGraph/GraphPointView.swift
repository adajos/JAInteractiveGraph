//
//  GraphPointView.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 3/17/16.
//  Copyright © 2016 Adams. All rights reserved.
//

import UIKit

@IBDesignable class GraphPointView: UIView {
    
    @IBInspectable var pointColor: UIColor = UIColor.whiteColor()
    @IBInspectable var pointStroke: UIColor = UIColor.redColor()
    
    
    
    internal var index = 0
    
    override func prepareForInterfaceBuilder() {
        self.backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
    }
    
    init(index: Int) {
        super.init(frame: CGRectZero)
        
        self.index = index
    }
    
    
    override func drawRect(rect: CGRect) {
        
        let paddingFromEdge :CGFloat = 1
        
        let circleSize :CGFloat = rect.width
        pointColor.setFill()
        pointStroke.setStroke()
        
        
        var point = CGPoint(x:circleSize / 2 + paddingFromEdge, y:circleSize / 2 + paddingFromEdge)
        point.x -= circleSize/2
        point.y -= circleSize/2
        
        let circle = UIBezierPath(ovalInRect:
            CGRect(origin: point,
                size: CGSize(width: circleSize - (paddingFromEdge * 2), height: circleSize - (paddingFromEdge * 2))))
        
        circle.fill()
        circle.stroke()
        
    }
}
