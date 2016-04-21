//
//  Extensions.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit

extension MKMapView {
    func adjustRegionToDisplayAnnotations(annotations: [MKAnnotation], animated: Bool) {
        var zoomRect = MKMapRectNull
        
        for annotation in annotations {
            let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
            let pointRect = MKMapRect(origin: annotationPoint, size: MKMapSize() )
            
            if MKMapRectIsNull(zoomRect) {
                zoomRect = pointRect
            } else {
                zoomRect = MKMapRectUnion(zoomRect, pointRect)
            }
        }
        
        let padding = UIEdgeInsets(top: 75, left: 50, bottom: 50, right: 50)
        self.setVisibleMapRect(zoomRect, edgePadding: padding, animated: animated)
    }
}

// MARK: - NSDate

func <(lhs: NSDate, rhs: NSDate) -> Bool { return lhs.compare(rhs) == .OrderedAscending }
func <=(lhs: NSDate, rhs: NSDate) -> Bool { return lhs < rhs || lhs == rhs }
func >(lhs: NSDate, rhs: NSDate) -> Bool { return lhs.compare(rhs) == .OrderedDescending }
func >=(lhs: NSDate, rhs: NSDate) -> Bool { return lhs > rhs || lhs == rhs }

extension NSDate {
    static var now: NSDate { return NSDate() }
    
    // MARK: Calendar
    var calendar: NSCalendar { return NSCalendar.currentCalendar() }
    
    // MARK: Month
    
    var monthAbbreviationString: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM"
        
        return formatter.stringFromDate(self)
    }
    
    var monthFullName: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM"
        
        return formatter.stringFromDate(self)
    }
    
    var monthOrdinal: Int {
        return calendar.ordinalityOfUnit(.Month, inUnit: .Year, forDate: self)
    }
    
    // MARK: Day
    
    var beginningOfDay: NSDate {
        let components = calendar.components([.Year, .Month, .Day], fromDate: self)
        return calendar.dateFromComponents(components)!
    }
    
    var isBeginningOfDay: Bool {
        return self == self.beginningOfDay
    }
    
    /// Represented as 00:00 of next day
    var endOfDay: NSDate {
        let components = NSDateComponents()
        components.day = 1
        return calendar.dateByAddingComponents(components, toDate: self.beginningOfDay, options: [])!
    }
    
    /// Represented as 00:00 of next day
    func isEndOf(date: NSDate) -> Bool {
        return self == date.endOfDay
    }
    
    var dayOrdinalInMonth: Int {
        return calendar.ordinalityOfUnit(.Day, inUnit: .Month, forDate: self)
    }
    
    var dayOrdinalInMonthString: String {
        return dayOrdinalInMonth.description
    }
    
    func plusDays(days: Int) -> NSDate {
        let interval = Double(days) * 24 * 60 * 60
        return NSDate(timeInterval: interval, sinceDate: self)
    }
    
    /// Returns the first day of the offset month.
    /// i.e. Count up `offset` number of months from date, then return first day of that month.
    func firstDayOfMonthWithOffset(offset: Int) -> NSDate {
        let components = calendar.components([.Year, .Month], fromDate: self)
        components.month += offset
        return calendar.dateFromComponents(components)!
    }
    
    var numberOfDaysInMonth: Int {
        return calendar.rangeOfUnit(.Day, inUnit: .Month, forDate: self).length
    }
    
    // MARK: Time
    
    var time: String {
        let formatter = NSDateFormatter()
        
        // Use alternate format string if user has 24-Hour Time enabled
        if userHas24HourTimeEnabled {
            formatter.dateFormat = "h:mm" // i.e. 07:00, 19:00
            
        } else {
            let components = calendar.components(.Minute, fromDate: self)
            print(components.minute)
            
//            if components.minute % 60 == 0 {
//                formatter.dateFormat = "ha" // i.e. 7AM, 7PM
//            } else {
                formatter.dateFormat = "h:mma" // i.e. 7:30AM, 7:00PM
//            }
        }
        
        return formatter.stringFromDate(self).lowercaseString
    }
}

extension UIColor {
    static func saving() -> UIColor {
        return UIColor.loading()
    }
    
    static func loading() -> UIColor {
        return UIColor(white: 0.8, alpha: 1.0)
    }
    
    static func closed() -> UIColor {
        return UIColor(red: 0.701961, green: 0.12549, blue: 0.0901961, alpha: 1.0)
    }
    
    static func open() -> UIColor {
        return UIColor(red: 0.505882, green: 0.737255, blue: 0.239216, alpha: 1.0)
    }
    
    static func warning() -> UIColor {
        return UIColor.orangeColor()
    }
}
