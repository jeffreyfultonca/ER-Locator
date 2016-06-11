//
//  ScheduleDay.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class ScheduleDay: NSObject, CloudKitRecordable, NSCoding {
    
    // MARK: - Stored Properties
    
    var record: CKRecord
    
    var date: NSDate
    
    var firstOpen: NSDate?
    var firstClose: NSDate?
    
    var secondOpen: NSDate?
    var secondClose: NSDate?
    
    // MARK: - Lifecycle
    
    required init(record: CKRecord) {
        self.record = record
        
        self.date = record["date"] as! NSDate
        
        self.firstOpen = record["firstOpen"] as? NSDate
        self.firstClose = record["firstClose"] as? NSDate
        
        self.secondOpen = record["secondOpen"] as? NSDate
        self.secondClose = record["secondClose"] as? NSDate
    }
    
    // MARK: - Computed Properties
    
    var erReference: CKReference {
        return record["er"] as! CKReference
    }
    
    // CloudKitRecordModelable
    var asCKRecord: CKRecord {
        record["date"] = date
        
        record["firstOpen"] = firstOpen
        record["firstClose"] = firstClose
        
        record["secondOpen"] = secondOpen
        record["secondClose"] = secondClose
        
        return record
    }
    
    // MARK: TimeSlots
    
    typealias TimeSlot = (open: NSDate, close: NSDate)
    
    var firstTimeSlot: TimeSlot? {
        guard let open = firstOpen, close = firstClose else { return nil }
        return TimeSlot(open: open, close: close)
    }
    
    var secondTimeSlot: TimeSlot? {
        guard let open = secondOpen, close = secondClose else { return nil }
        return TimeSlot(open: open, close: close)
    }
    
    // MARK: Predicates
    
    static var OpenNowPredicate: NSPredicate {
        let now = NSDate()
        return NSPredicate(format: "firstOpen <= %@ AND firstClose > %@", now, now)
    }
    
    // MARK: - NSCoding
    
    struct PropertyKey {
        static let Record = "RecordKey"
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(record, forKey: PropertyKey.Record)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let record = aDecoder.decodeObjectForKey(PropertyKey.Record) as! CKRecord
        self.init(record: record)
    }
    
    // Equateable for NSObject
    override func isEqual(object: AnyObject?) -> Bool {
        guard let object = object as? ScheduleDay else { return false }
        
        let same = self.recordID == object.recordID
        print("ScheduleDay.isEqual: \(same)")
        return same
    }
}
