//
//  ScheduleDay.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class ScheduleDay: CloudKitRecord, CloudKitRecordProtocol {
    
    // MARK: - Properties
    var date: NSDate
    
    var firstOpen: NSDate?
    var firstClose: NSDate?
    
    var secondOpen: NSDate?
    var secondClose: NSDate?
    
    // MARK: - Lifecycle
    
    override init(record: CKRecord) {
        self.date = record["date"] as! NSDate
        
        self.firstOpen = record["firstOpen"] as? NSDate
        self.firstClose = record["firstClose"] as? NSDate
        
        self.secondOpen = record["secondOpen"] as? NSDate
        self.secondClose = record["secondClose"] as? NSDate
        
        super.init(record: record)
    }
    
    // MARK: - CloudKitProtocol
    static var recordType = "ScheduleDay"
    
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
    
    
}