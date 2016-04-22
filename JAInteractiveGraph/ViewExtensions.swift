//
//  ViewExtensions.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 4/14/16.
//  Copyright © 2016 adams. All rights reserved.
//

import UIKit

extension UIView {
    func setNewViewPositionWithSameSize(originPoint : CGPoint) {
        self.frame = CGRect(origin: originPoint, size: self.frame.size)
    }
}




