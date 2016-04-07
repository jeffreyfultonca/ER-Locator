//
//  Functions.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-05.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

func runOnMainQueue(closure: ()->() ) {
    NSOperationQueue.mainQueue().addOperationWithBlock(closure)
}

/// True if user has enabled system wide 24-Hour Time in Date & Time settings.
var userHas24HourTimeEnabled: Bool {
    let formatString = NSDateFormatter.dateFormatFromTemplate("j", options: 0, locale: NSLocale.currentLocale())!
    return !formatString.containsString("a")
}