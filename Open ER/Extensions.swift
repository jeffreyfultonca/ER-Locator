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
    static var now: NSDate {
        return NSDate()
    }
    
    /// 00:00 of todays date.
    var beginningOfDay: NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day], fromDate: self)
        return calendar.dateFromComponents(components)!
    }
    
    var isBeginningOfDay: Bool {
        return self == self.beginningOfDay
    }
    
    var endOfDay: NSDate {
        let components = NSDateComponents()
        components.day = 1
        var date = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: self.beginningOfDay, options: [])!
        date = date.dateByAddingTimeInterval(-1)
        return date
    }
    
    var isEndOfDay: Bool {
        return self == self.endOfDay
    }
    
    var inPast: Bool {
        return self < NSDate()
    }
    
    var inFuture: Bool {
        return self > NSDate()
    }
    
    var shortDate: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM d"
        
        return formatter.stringFromDate(self)
    }
    
    var day: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "d"
        
        return formatter.stringFromDate(self)
    }
    
    var month: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM"
        
        return formatter.stringFromDate(self)
    }
    
    var time: String {
        let formatter = NSDateFormatter()
        
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.Minute, fromDate: self)
        
        if components.minute % 60 == 1 {
            formatter.dateFormat = "ha" // i.e. 7AM, 7PM
        } else {
            formatter.dateFormat = "h:mma" // i.e. 7:30AM, 7:00PM
        }
        
        // Use alternate format string if user has 24-Hour Time enabled
        let formatString = NSDateFormatter.dateFormatFromTemplate("j", options: 0, locale: NSLocale.currentLocale())!
        let display24HourTime = !formatString.containsString("a")
        if display24HourTime {
            formatter.dateFormat = "h:mm" // i.e. 07:00, 19:00
        }
        
        return formatter.stringFromDate(self).lowercaseString
    }
    
    func plusDays(days: Int) -> NSDate {
        let interval = Double(days) * 24 * 60 * 60
        return NSDate(timeInterval: interval, sinceDate: self)
    }
}

extension UIColor {
    static func closed() -> UIColor {
        return UIColor(red: 0.701961, green: 0.12549, blue: 0.0901961, alpha: 1.0)
    }
    
    static func open() -> UIColor {
        return UIColor(red: 0.505882, green: 0.737255, blue: 0.239216, alpha: 1.0)
    }
}
