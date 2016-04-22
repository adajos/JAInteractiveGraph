//
//  SimpleGraphDataPoint.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/21/16.
//  Copyright © 2016 adams. All rights reserved.
//

public struct SimpleGraphDataPoint : GraphableDataPoint {
    public var value: Int = 0
    public var description: String = ""
    
    public init(value: Int) {
        self.value = value
    }
    
    public init(_ value: Int, _ description: String) {
        self.init(value: value)
        self.description = description
    }
}
