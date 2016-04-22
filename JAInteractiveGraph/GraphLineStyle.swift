//
//  GraphLineStyle.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/21/16.
//  Copyright © 2016 adams. All rights reserved.
//

public enum GraphLineStyle : Int {
    case Curved = 0
    case Straight = 1
    
    public init(rawValue: Int) {
        if rawValue == 0 {
            self = .Curved
        }
        else {
            self = .Straight
        }
    }
    
}

