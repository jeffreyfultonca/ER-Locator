//
//  ScheduleDay.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class ScheduleDay: CloudKitRecord, CloudKitRecordProtocol {
    
    // MARK: - CloudKitProtocol
    static var recordType = "ScheduleDay"
    
    // MARK: - Properties
    var date: NSDate
    
    var firstOpen: NSDate?
    var firstClose: NSDate?
    
    var secondOpen: NSDate?
    var secondClose: NSDate?
    
    // MARK: - Lifecycle
    
    init(
        recordID: CKRecordID,
        date: NSDate,
        firstOpen: NSDate? = nil,
        firstClose: NSDate? = nil,
        secondOpen: NSDate? = nil,
        secondClose: NSDate? = nil)
    {
        self.date = date
        
        self.firstOpen = firstOpen
        self.firstClose = firstClose
        
        self.secondOpen = secondOpen
        self.secondClose = secondClose
        
        super.init(recordID: recordID)
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