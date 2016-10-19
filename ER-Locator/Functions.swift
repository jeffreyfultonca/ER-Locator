//
//  Functions.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-04-05.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

/// Execute the supplied closure on the main queue
/// after the specified number of seconds.
func delay(inSeconds delay:Double, closure: @escaping ()->()) {
    //TODO: Confirm this works.
    let dispatchTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: closure)
}

func runOnMainQueue(_ closure: @escaping ()->() ) {
    OperationQueue.main.addOperation(closure)
}

/// True if user has enabled system wide 24-Hour Time in Date & Time settings.
var userHas24HourTimeEnabled: Bool {
    //TODO: Confirm this works.
    let formatString = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!
    return !formatString.contains("a")
}
