//
//  DateRange.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-14.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

struct DateRange : Sequence {
    var calendar: Calendar
    var startDate: Date
    var endDate: Date
    var stepUnits: NSCalendar.Unit
    var stepValue: Int
    
    init(
        calendar: Calendar,
        startDate: Date,
        endDate: Date,
        stepUnits: NSCalendar.Unit,
        stepValue: Int )
    {
        self.calendar = calendar
        // Less one day to make inclusive
        self.startDate = (calendar as NSCalendar).date(
            byAdding: stepUnits,
            value: -stepValue,
            to: startDate,
            options: []
        )!
        self.endDate = endDate
        self.stepUnits = stepUnits
        self.stepValue = stepValue
    }
    
    func makeIterator() -> Iterator {
        return Iterator(range: self)
    }
    
    struct Iterator: IteratorProtocol {
        
        var range: DateRange
        
        mutating func next() -> Date? {
            let nextDate = (range.calendar as NSCalendar).date(
                byAdding: range.stepUnits,
                value: range.stepValue,
                to: range.startDate,
                options: []
            )!
            
            guard nextDate <= range.endDate else { return nil }
            
            range.startDate = nextDate
            return nextDate
        }
    }
}
