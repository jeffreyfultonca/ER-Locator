//
//  Functions.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-04-05.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

/// Execute the supplied closure on the main queue
/// after the specified number of seconds.
func delay(inSeconds delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(),
        closure
    )
}

func runOnMainQueue(closure: ()->() ) {
    NSOperationQueue.mainQueue().addOperationWithBlock(closure)
}

/// True if user has enabled system wide 24-Hour Time in Date & Time settings.
var userHas24HourTimeEnabled: Bool {
    let formatString = NSDateFormatter.dateFormatFromTemplate("j", options: 0, locale: NSLocale.currentLocale())!
    return !formatString.containsString("a")
}