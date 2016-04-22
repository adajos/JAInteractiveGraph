//
//  GraphViewDataSourceDelegate.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/21/16.
//  Copyright © 2016 adams. All rights reserved.
//

public protocol GraphViewDataSourceDelegate {
    func getData() -> [GraphableDataPoint]
    func dataUpdated(data: [GraphableDataPoint])
}
