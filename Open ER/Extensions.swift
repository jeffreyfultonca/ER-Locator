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

extension NSDate: Comparable {}
public func ==(lhs: NSDate, rhs: NSDate) -> Bool { return lhs.compare(rhs) == .OrderedSame }
public func <(lhs: NSDate, rhs: NSDate) -> Bool { return lhs.compare(rhs) == .OrderedAscending }

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
    
    var monthOrdinalForEra: Int {
        return calendar.ordinalityOfUnit(.Month, inUnit: .Era, forDate: self)
    }
    
    var datesInMonth: [NSDate] {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Month, .Year], fromDate: self)
        
        let startDate = calendar.dateFromComponents(components)!
        
        components.month += 1
        components.day = 0 // Results in last day of previous month
        
        let endDate = calendar.dateFromComponents(components)!
        
        let dateRange = DateRange(
            calendar: calendar,
            startDate: startDate,
            endDate: endDate,
            stepUnits: .Day,
            stepValue: 1
        )
        
        return Array<NSDate>(dateRange)
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
        return calendar.dateByAddingUnit(.Day, value: days, toDate: self, options: [])!
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
    
    /**
     Attempts to returns new NSDate at the specified hour. i.e. 8 -> 8AM or 20 -> 8PM
     
     - parameters:
        - hour: Integer between 0 and 23 else self is returned.
     
     - returns:
     NSDate at the specified hour, or `self` if new date could not be calculated.
    */
    func atHour(hour: Int) -> NSDate {
        guard hour >= 0 && hour < 24 else { return self }
        return calendar.dateBySettingHour(hour, minute: 0, second: 0, ofDate: self, options: .MatchFirst) ?? self
    }
    
    // MARK: Time
    
    var time: String {
        let formatter = NSDateFormatter()
        
        // Use alternate format string if user has 24-Hour Time enabled
        if userHas24HourTimeEnabled {
            formatter.dateFormat = "h:mm" // i.e. 07:00, 19:00
            
        } else {
//            let components = calendar.components(.Minute, fromDate: self)
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
    static func pinColorForOpenER() -> UIColor {
        return UIColor.redColor()
    }
    
    static func pinColorForClosedER() -> UIColor {
        return UIColor.redColor().colorWithAlphaComponent(0.25)
    }
    
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

extension String {
    func stringByRemovingNonNumericCharacters() -> String {
        return self.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
    }
}

extension SequenceType where Generator.Element: CloudKitModal {
    var mostRecentlyModifiedAt: NSDate? {
        let recordsWithModificationDates = self.filter { $0.record.modificationDate != nil }
        let modificationDates = recordsWithModificationDates.map { $0.record.modificationDate! }
        let sortedModificationDates = modificationDates.sort(>)
        
        return sortedModificationDates.first
    }
}

extension SequenceType where Generator.Element: ER {
    func nearestLocation(location: CLLocation?) -> [ER] {
        guard let location = location else { return self as! [ER] }
        return self.sort { $0.location.distanceFromLocation(location) < $1.location.distanceFromLocation(location) }
    }
    
    func limit(limit: Int?) -> [ER] {
        let ers = self as! [ER]
        guard let limit = limit else { return ers }
        return Array(ers.prefix(limit))
    }
    
    var openNow: [ER] {
        return self.filter { $0.openNow }
    }
    
    var possiblyClosed: [ER] {
        return self.filter { $0.openNow == false }
    }
}

extension SequenceType where Generator.Element: ScheduleDay {
    var scheduledToday: Set<ScheduleDay> {
        let today = NSDate().beginningOfDay
        let todaysScheduleDays = self.filter { $0.date == today }
        return Set(todaysScheduleDays)
    }
}

extension NSOperation {
    func withDependency(dependency: NSOperation) -> Self {
        self.addDependency(dependency)
        return self
    }
    
    func withDependencies(dependencies: [NSOperation]) -> Self {
        dependencies.forEach { self.addDependency($0) }
        return self
    }
}
