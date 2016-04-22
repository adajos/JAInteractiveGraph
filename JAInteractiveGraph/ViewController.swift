//
//  ViewController.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/14/16.
//  Copyright © 2016 adams. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var graphView: GraphView!
    
    private static let dummyData: [GraphableDataPoint] = [CustomGraphDataPoint(value: 12, 2010), CustomGraphDataPoint(value: 0, 2011), CustomGraphDataPoint(value: -4, 2012), CustomGraphDataPoint(value: 0, 2013)]
    
    private var data: [GraphableDataPoint] = ViewController.dummyData
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.graphView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func maxTapped(sender: AnyObject) {
        
        self.graphView.animateGraphPointsToValues([CustomGraphDataPoint(value: 12, 2010), CustomGraphDataPoint(value: 6, 2011), CustomGraphDataPoint(value: -12, 2012), CustomGraphDataPoint(value: 9, 2013)], duration: 0.5)
    }
    @IBAction func reloadTapped(sender: AnyObject) {
        self.data = ViewController.dummyData
        self.graphView.reloadData()
    }
    
}

struct CustomGraphDataPoint: GraphableDataPoint {
    typealias Year = Int
    
    var value: Int = 0
    var year: Year = 0
    
    var description: String {
        get { return "\(year)" }
    }
    
    init(value: Int) {
        self.value = value
    }
    
    init(value: Int, _ year: Year) {
        self.init(value: value)
        self.year = year
    }
}

extension ViewController: GraphViewDataSourceDelegate {
    func getData() -> [GraphableDataPoint] {
        return data
    }
    
    func dataUpdated(data: [GraphableDataPoint]) {
        self.data = data
        NSLog("data is \(self.data)")
    }
}

