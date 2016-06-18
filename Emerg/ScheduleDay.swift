//
//  ScheduleDay.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

/// Represents a particular day in time for a single Emerg. 
/// i.e. An Emerg can have 0 to 365 ScheduleDays per year, 366 in leap years.
class ScheduleDay: NSObject, CloudKitModal, NSCoding {
    
    // MARK: - Stored Properties
    var record: CKRecord
    
    // MARK: - Lifecycle
    
    required init(record: CKRecord) {
        self.record = record
    }
    
    // MARK: - Computed Properties
    
    var date: NSDate {
        get { return record["date"] as! NSDate }
        set { record["date"] = newValue }
    }
    var firstOpen: NSDate? {
        get { return record["firstOpen"] as? NSDate }
        set { record["firstOpen"] = newValue }
    }
    var firstClose: NSDate? {
        get { return record["firstClose"] as? NSDate }
        set { record["firstClose"] = newValue }
    }
    
    var erReference: CKReference {
        return record["er"] as! CKReference
    }
    
    // MARK: TimeSlots
    
    /// Representation of an Open/Close date pair. Currently there is only one, but future versions may have more.
    /// Makes display in UI easier.
    typealias TimeSlot = (open: NSDate, close: NSDate)
    
    /// See TimeSlot definition for additional details.
    var firstTimeSlot: TimeSlot? {
        guard let open = firstOpen, close = firstClose else { return nil }
        return TimeSlot(open: open, close: close)
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
    
    // Hashable, Equatable
    
    // Required for determining uniqueness in Sets
    override var hashValue: Int {
        return recordID.recordName.hashValue
    }
    
    // Required for ==
    override func isEqual(object: AnyObject?) -> Bool {
        guard let rhs = object as? ScheduleDay else { return false }
        return self.recordID == rhs.recordID
    }
    
    // MARK: Predicates
    
    /// Uses current time on device to determine open/closed status.  
    static var OpenNowPredicate: NSPredicate {
        let now = NSDate()
        return NSPredicate(format: "firstOpen <= %@ AND firstClose > %@", now, now)
    }
}
