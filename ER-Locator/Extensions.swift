//
//  Extensions.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit

extension MKMapView {
    func adjustRegionToDisplayAnnotations(_ annotations: [MKAnnotation], animated: Bool) {
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

extension Date {
    static var now: Date { return Date() }
    
    // MARK: Calendar
    var calendar: Calendar { return Calendar.current }
    
    // MARK: Month
    
    var monthAbbreviationString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return formatter.string(from: self)
    }
    
    var monthFullName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        return formatter.string(from: self)
    }
    
    var monthOrdinal: Int {
        return calendar.ordinality(of: .month, in: .year, for: self)!
    }
    
    var monthOrdinalForEra: Int {
        return calendar.ordinality(of: .month, in: .era, for: self)!
    }
    
    var datesInMonth: [Date] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.month, .year], from: self)
        
        let startDate = calendar.date(from: components)!
        
        components.month = components.month! + 1
        components.day = 0 // Results in last day of previous month
        
        let endDate = calendar.date(from: components)!
        
        return Array<Date>(startDate...endDate)
    }
    
    // MARK: Day
    
    var beginningOfDay: Date {
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components)!
    }
    
    var isBeginningOfDay: Bool {
        return self == self.beginningOfDay
    }
    
    /// Represented as 00:00 of next day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        
        return calendar.date(byAdding: components, to: self.beginningOfDay)!
    }
    
    /// Represented as 00:00 of next day
    func isEndOf(_ date: Date) -> Bool {
        return self == date.endOfDay
    }
    
    var dayOrdinalInMonth: Int {
        return calendar.ordinality(of: .day, in: .month, for: self)!
    }
    
    var dayOrdinalInMonthString: String {
        return dayOrdinalInMonth.description
    }
    
    func plusDays(_ days: Int) -> Date {
        return calendar.date(byAdding: .day, value: days, to: self)!
    }
    
    /// Returns the first day of the offset month.
    /// i.e. Count up `offset` number of months from date, then return first day of that month.
    func firstDayOfMonthWithOffset(_ offset: Int) -> Date {
        var components = calendar.dateComponents([.year, .month], from: self)
        components.month = components.month! + offset
        
        return calendar.date(from: components)!
    }
    
    var numberOfDaysInMonth: Int {
        return calendar.range(of: .day, in: .month, for: self)!.count
    }
    
    /**
     Attempts to returns new NSDate at the specified hour. i.e. 8 -> 8AM or 20 -> 8PM
     
     - parameters:
        - hour: Integer between 0 and 23 else self is returned.
     
     - returns:
     NSDate at the specified hour, or `self` if new date could not be calculated.
    */
    func atHour(_ hour: Int) -> Date {
        guard hour >= 0 && hour < 24 else { return self }
        
        return calendar.date(bySetting: .hour, value: hour, of: self)!
    }
    
    // MARK: Time
    
    var time: String {
        let formatter = DateFormatter()
        
        // Use alternate format string if user has 24-Hour Time enabled
        if userHas24HourTimeEnabled {
            formatter.dateFormat = "h:mm" // i.e. 07:00, 19:00
        } else {
            formatter.dateFormat = "h:mma" // i.e. 7:30AM, 7:00PM
        }
        
        return formatter.string(from: self).lowercased()
    }
}

extension Date: Strideable {
    public typealias Stride = Int
    
    public func advanced(by n: Date.Stride) -> Date {
        let calendar = Calendar.current
        let nextDate = calendar.date(byAdding: .day, value: 1, to: self)!
        return nextDate
    }
    
    public func distance(to other: Date) -> Date.Stride {
        let calendar = Calendar.current
        let distance = calendar.dateComponents([.day], from: self, to: other).day ?? 0
        return distance
    }
}


extension UIColor {
    // TODO: Make these static vars if possible.
    static func pinColorForOpenER() -> UIColor {
        return UIColor.red
    }
    
    static func pinColorForClosedER() -> UIColor {
        return UIColor.red.withAlphaComponent(0.25)
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
        return UIColor.orange
    }
}

extension String {
    func stringByRemovingNonNumericCharacters() -> String {
        return self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}

extension Sequence where Iterator.Element: CloudKitModel {
    var mostRecentlyModifiedAt: Date? {
        let recordsWithModificationDates = self.filter { $0.record.modificationDate != nil }
        let modificationDates = recordsWithModificationDates.map { $0.record.modificationDate! }
        let sortedModificationDates = modificationDates.sorted(by: >)
        
        return sortedModificationDates.first
    }
}

extension Sequence where Iterator.Element: ER {
    func nearestLocation(_ location: CLLocation?) -> [ER] {
        guard let location = location else { return self as! [ER] }
        return self.sorted { $0.location.distance(from: location) < $1.location.distance(from: location) }
    }
    
    func limit(_ limit: Int?) -> [ER] {
        let ers = self as! [ER]
        guard let limit = limit else { return ers }
        return Array(ers.prefix(limit))
    }
    
    var isOpenNow: [ER] {
        return self.filter { $0.isOpenNow }
    }
    
    var possiblyClosed: [ER] {
        return self.filter { $0.isOpenNow == false }
    }
}

extension Sequence where Iterator.Element: ScheduleDay {
    var scheduledToday: Set<ScheduleDay> {
        let today = Date().beginningOfDay
        let todaysScheduleDays = self.filter { $0.date == today }
        return Set(todaysScheduleDays)
    }
}

extension Operation {
    func withDependency(_ dependency: Operation) -> Self {
        self.addDependency(dependency)
        return self
    }
    
    func withDependencies(_ dependencies: [Operation]) -> Self {
        dependencies.forEach { self.addDependency($0) }
        return self
    }
}
