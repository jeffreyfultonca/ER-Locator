//
//  DateRange.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-14.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

struct DateRange : SequenceType {
    var calendar: NSCalendar
    var startDate: NSDate
    var endDate: NSDate
    var stepUnits: NSCalendarUnit
    var stepValue: Int
    
    init(
        calendar: NSCalendar,
        startDate: NSDate,
        endDate: NSDate,
        stepUnits: NSCalendarUnit,
        stepValue: Int )
    {
        self.calendar = calendar
        // Less one day to make inclusive
        self.startDate = calendar.dateByAddingUnit(
            stepUnits,
            value: -stepValue,
            toDate: startDate,
            options: []
        )!
        self.endDate = endDate
        self.stepUnits = stepUnits
        self.stepValue = stepValue
    }
    
    func generate() -> Generator {
        return Generator(range: self)
    }
    
    struct Generator: GeneratorType {
        
        var range: DateRange
        
        mutating func next() -> NSDate? {
            let nextDate = range.calendar.dateByAddingUnit(
                range.stepUnits,
                value: range.stepValue,
                toDate: range.startDate,
                options: []
            )!
            
            guard nextDate <= range.endDate else { return nil }
            
            range.startDate = nextDate
            return nextDate
        }
    }
}
