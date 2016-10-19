//
//  NetworkActivityIndicatorOperation.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-08.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

/**
 Sets visibility of iOS's network activitiy indicator in status bar.
 
 - Parameters:
    - visible: Determines whether to show or hide indicator.
 */
class NetworkActivityIndicatorOperation: Operation {
    
    private let visible: Bool
    
    init(setVisible visible: Bool) {
        self.visible = visible
    }
    
    override func main() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = visible
    }
}
