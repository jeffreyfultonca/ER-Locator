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
    
    var time: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ha" // i.e. 7AM, 7PM
        
        // Use alternate format string if user has 24-Hour Time enabled
        let formatString = NSDateFormatter.dateFormatFromTemplate("j", options: 0, locale: NSLocale.currentLocale())!
        let display24HourTime = !formatString.containsString("a")
        if display24HourTime {
            formatter.dateFormat = "h:mm" // i.e. 07:00, 19:00
        }
        
        return formatter.stringFromDate(self)
    }
    
    /// Timestamp used by database.
    var timestamp: String {
        let df = NSDateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        df.timeZone = NSTimeZone(abbreviation: "UTC")
        
        return df.stringFromDate(self)
    }
}
