//
//  ScheduleDay.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

/// Represents a particular day in time for a single ER. 
/// i.e. An ER can have 0 to 365 ScheduleDays per year, 366 in leap years.
class ScheduleDay: NSObject, CloudKitModel, NSCoding {
    
    // MARK: - Stored Properties
    var record: CKRecord
    
    // MARK: - Lifecycle
    
    required init(record: CKRecord) {
        self.record = record
    }
    
    // MARK: - Computed Properties
    
    var date: Date {
        get { return record["date"] as! Date }
        set { record["date"] = newValue }
    }
    var firstOpen: Date? {
        get { return record["firstOpen"] as? Date }
        set { record["firstOpen"] = newValue }
    }
    var firstClose: Date? {
        get { return record["firstClose"] as? Date }
        set { record["firstClose"] = newValue }
    }
    
    var erReference: CKReference {
        return record["er"] as! CKReference
    }
    
    // MARK: TimeSlots
    
    /// Representation of an Open/Close date pair. Currently there is only one, but future versions may have more.
    /// Makes display in UI easier.
    typealias TimeSlot = (open: Date, close: Date)
    
    /// See TimeSlot definition for additional details.
    var firstTimeSlot: TimeSlot? {
        guard let open = firstOpen, let close = firstClose else { return nil }
        return TimeSlot(open: open, close: close)
    }
    
    // MARK: - NSCoding
    
    struct PropertyKey {
        static let Record = "RecordKey"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(record, forKey: PropertyKey.Record)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let record = aDecoder.decodeObject(forKey: PropertyKey.Record) as! CKRecord
        self.init(record: record)
    }
    
    // Hashable, Equatable
    
    // Required for determining uniqueness in Sets
    override var hashValue: Int {
        return recordID.recordName.hashValue
    }
    
    // Required for ==
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ScheduleDay else { return false }
        return self.recordID == rhs.recordID
    }
    
    // MARK: Predicates
    
    /// Uses current time on device to determine open/closed status.  
    static var OpenNowPredicate: NSPredicate {
        let now = Date()
        return NSPredicate(format: "firstOpen <= %@ AND firstClose > %@", now, now)
    }
}
