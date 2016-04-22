//
//  GraphableDataPoint.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/21/16.
//  Copyright © 2016 adams. All rights reserved.
//

public protocol GraphableDataPoint {
    var value: Int { get set}
    var description: String {get}
    
    init(value: Int)
}


//let's provide our own max/minElement() in lieu of making protocol GraphableDatPoint
//adopt Comparable/Equatable.
extension SequenceType where Generator.Element == GraphableDataPoint {
    func maxElement() -> GraphableDataPoint {
        return self.sort({ $0.value > $1.value }).first!
    }
    
    func minElement() -> GraphableDataPoint {
        return self.sort({ $0.value < $1.value }).first!
    }
}







