 //
//  ERService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CoreLocation
import CloudKit

class ERService {
    static let sharedInstance = ERService()
    
    // MARK: - CloudKit Properties
    private let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    // MARK: - ERs
    
    /// Handler closures execute on main thread.
    func fetchAllERs(failure failure: (ErrorType)->(), success: ([ER])->() ) {
        let query = CKQuery(recordType: ER.recordType, predicate: NSPredicate(value: true) )
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            // TODO: Handler possible errors? Or is passing them back up good?
            guard error == nil else { return runOnMainQueue { failure(error!) } }
            guard let records = records else {
                return runOnMainQueue { failure( Error.UnableToAccessReturnedRecordsOfType(ER.recordType) ) }
            }
            
            let ers = records.map { record -> ER in
                let recordID = record.recordID
                let name = record["name"] as! String
                let location = record["location"] as! CLLocation
                
                return ER(recordID: recordID, name: name, location: location)
            }
            
            runOnMainQueue { success(ers) }
        }   
    }
    
    /// Handler closures execute on main thread.
    func fetchOpenERsNearestLocation(location: CLLocation, failure: (ErrorType)->(), success: ([ER])->() ) {
        let query = CKQuery(recordType: ER.recordType, predicate: NSPredicate(value: true) )
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            // TODO: Handler possible errors? Or is passing them back up good?
            guard error == nil else { return runOnMainQueue { failure(error!) } }
            guard let records = records else {
                return runOnMainQueue { failure( Error.UnableToAccessReturnedRecordsOfType(ER.recordType) ) }
            }
            
            let ers = records.map { record -> ER in
                let recordID = record.recordID
                let name = record["name"] as! String
                let location = record["location"] as! CLLocation
                
                return ER(recordID: recordID, name: name, location: location)
            }
            
            runOnMainQueue { success(ers) }
        }
    }
    
    // MARK: - ScheduleDays
    
    enum ScheduleDaysFetchResult {
        case Success([ScheduleDay])
        case Failure(ErrorType)
    }
    typealias ScheduleDaysFetchHandler = (ScheduleDaysFetchResult)->()
    
    /// Handler closures execute on main thread.
    func fetchScheduleDaysForERTwo(er: ER, handler: ScheduleDaysFetchHandler ) {}
    
    func fetchScheduleDaysForER(er: ER, handler: (ScheduleDaysFetchResult)->() ) {
        let predicate = NSPredicate(format: "er == %@ AND date >= %@", er.recordID, NSDate.now.beginningOfDay)
        let query = CKQuery(recordType: ScheduleDay.recordType, predicate: predicate)
        query.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            // TODO: Handler possible errors? Or is passing them back up good?
            guard error == nil else { return runOnMainQueue { handler( .Failure(error!) ) } }
            guard let records = records else {
                return runOnMainQueue {
                    handler( .Failure( Error.UnableToAccessReturnedRecordsOfType(ScheduleDay.recordType) ) )
                }
            }
            
            let scheduleDays = records.map({ record -> ScheduleDay in
                let recordID = record.recordID
                let date = record["date"] as! NSDate
                
                let firstOpen = record["firstOpen"] as? NSDate
                let firstClose = record["firstClose"] as? NSDate
                
                let secondOpen = record["secondOpen"] as? NSDate
                let secondClose = record["secondClose"] as? NSDate
                
                return ScheduleDay(
                    recordID: recordID,
                    date: date,
                    firstOpen: firstOpen,
                    firstClose: firstClose,
                    secondOpen: secondOpen,
                    secondClose: secondClose
                )
            })
            
            runOnMainQueue { handler( .Success(scheduleDays) ) }
        }
    }
    
    enum ScheduleDayFetchResult {
        case Success(ScheduleDay?)
        case Failure(ErrorType)
    }
    
    /// Handler executes on main thread.
    func fetchScheduleDayForER(er: ER, onDate date: NSDate, handler: (ScheduleDayFetchResult)->() ) {
        
        let predicate = NSPredicate(format: "er == %@ AND date == %@", er.recordID, date)
        let query = CKQuery(recordType: ScheduleDay.recordType, predicate: predicate)
        query.sortDescriptors = [ NSSortDescriptor(key: "modificationDate", ascending: true) ]
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            
            // TODO: Handler possible errors? Or is passing them back up good?
            guard error == nil else { return runOnMainQueue { handler( .Failure(error!) ) } }
            guard let records = records else {
                return runOnMainQueue {
                    handler( .Failure( Error.UnableToAccessReturnedRecordsOfType(ScheduleDay.recordType) ) )
                }
            }
            
            // Error conditions may result in duplicate records for the same day. 
            // We only want to use the most recently updated one... I think?
            guard let record = records.first else {
                runOnMainQueue { handler(.Success(nil)) }
                return
            }
            
            let recordID = record.recordID
            let date = record["date"] as! NSDate
            
            let firstOpen = record["firstOpen"] as? NSDate
            let firstClose = record["firstClose"] as? NSDate
            
            let secondOpen = record["secondOpen"] as? NSDate
            let secondClose = record["secondClose"] as? NSDate
            
            let scheduleDay = ScheduleDay(
                recordID: recordID,
                date: date,
                firstOpen: firstOpen,
                firstClose: firstClose,
                secondOpen: secondOpen,
                secondClose: secondClose
            )
            
            runOnMainQueue { handler( .Success(scheduleDay) ) }
        }
    }
}