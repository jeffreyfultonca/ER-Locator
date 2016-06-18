//
//  Day.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

func ==(lhs: Day, rhs: Day) -> Bool { return lhs.date == rhs.date }
func <(lhs: Day, rhs: Day) -> Bool { return lhs.date < rhs.date }

struct Day: ForwardIndexType, Comparable, CustomStringConvertible {
    let date: NSDate
    
    // ForwardIndexType
    
    func advancedBy(n: Day.Distance) -> Day {
        // TODO: Use currentCalendar instead.
        let nextDate = date.dateByAddingTimeInterval(60*60*24*Double(n))
        return Day(date: nextDate)
    }
    
    // _Incrementable
    
    func successor() -> Day {
        return advancedBy(1)
    }
    
    // CustomStringConvertible
    var description: String {
        return date.description
    }
}

