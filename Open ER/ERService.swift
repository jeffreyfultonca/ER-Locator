//
//  ERService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CoreLocation
import CloudKit
import UIKit

class ERService {
    static let sharedInstance = ERService()
    
    // MARK: - CloudKit Properties
    private let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    // MARK: - Network Activity Indicator Helper
    
    func setNetworkActivityIndicatorVisible(visible: Bool) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = visible
    }
    
    // MARK: - ERs
    
    /// Handler closures execute on main thread.
    func fetchAllERs(failure failure: (ErrorType)->(), success: ([ER])->() ) {
        let query = CKQuery(recordType: ER.recordType, predicate: NSPredicate(value: true) )
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        setNetworkActivityIndicatorVisible(true)
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            runOnMainQueue { self.setNetworkActivityIndicatorVisible(false) }
            
            // TODO: Handler possible errors? Or is passing them back up good?
            guard error == nil else { return runOnMainQueue { failure(error!) } }
            guard let records = records else {
                return runOnMainQueue { failure( Error.UnableToAccessReturnedRecordsOfType(ER.recordType) ) }
            }
            
            let ers = records.map { ER(record: $0) }
            
            runOnMainQueue { success(ers) }
        }   
    }
    
    /// Handler closures execute on main thread.
    func fetchOpenERsNearestLocation(location: CLLocation, handler: (CloudKitRecordableFetchResult<ER>)->() ) {
        
        // Limit to 3.
        // Sort by proximity.
        // Where ScheduleDay exists with today's date
        // Where ScheduleDay.firstOpen <= now && ScheduleDay.firstClose > now // Maybe factor in travel time? May slow load time.
        let now = NSDate.now
        let scheduleDaysPredicate = NSPredicate(format: "firstOpen <= %@ AND firstClose > %@", now, now)
        let scheduleDaysQuery = CKQuery(recordType: ScheduleDay.recordType, predicate: scheduleDaysPredicate)
        
        setNetworkActivityIndicatorVisible(true)
        
        publicDatabase.performQuery(scheduleDaysQuery, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            runOnMainQueue { self.setNetworkActivityIndicatorVisible(false) }
            
            guard error == nil else { return runOnMainQueue { handler( .Failure(error!) ) } }
            guard let records = records else {
                return runOnMainQueue { handler( .Failure( Error.UnableToAccessReturnedRecordsOfType(ER.recordType) ) ) }
            }
            
            let erReferences = records.map({ scheduleDayRecord -> CKReference in
                let reference = scheduleDayRecord["er"] as! CKReference
                return reference
            })
            
            let erPredicate = NSPredicate(format: "recordID IN %@", erReferences)
            let erQuery = CKQuery(recordType: ER.recordType, predicate: erPredicate)
            
            // Would love to sort in query... but variable results are returned.
//            erQuery.sortDescriptors = [CKLocationSortDescriptor(key: "location", relativeLocation: location)]
            
            var ers = [ER]()
            
            self.setNetworkActivityIndicatorVisible(true)
            
            let erOperation = CKQueryOperation(query: erQuery)
            erOperation.database = self.publicDatabase
            
            // Would love to limit results in Operation... but variable results are returned.
//            erOperation.resultsLimit = 3
            
            erOperation.recordFetchedBlock = { record in
                ers.append( ER(record: record) )
            }
            erOperation.queryCompletionBlock = { (cursor, error) in
                runOnMainQueue { self.setNetworkActivityIndicatorVisible(false) }
                
                guard error == nil else { return runOnMainQueue { handler( .Failure(error!) ) } }
                
                // Having to sort and limit post request due to variable results being returned if sortDescriptors & resultsLimit is used.
                ers.sortInPlace { (first, second) -> Bool in
                    return first.location.distanceFromLocation(location) < second.location.distanceFromLocation(location)
                }
                
                // Limit to top three results
                ers = Array( ers.prefix(3) )
                
                runOnMainQueue { handler( .Success(ers) ) }
            }
            erOperation.start()
        }
    }
    
    // MARK: - ScheduleDays
    
    
    
    /// Handler executes on main thread.
    func fetchScheduleDaysForER(er: ER, handler: (ScheduleDaysFetchResult)->() ) {
        let predicate = NSPredicate(format: "er == %@ AND date >= %@", er.recordID, NSDate.now.beginningOfDay)
        let query = CKQuery(recordType: ScheduleDay.recordType, predicate: predicate)
        query.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
        
        setNetworkActivityIndicatorVisible(true)
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            runOnMainQueue { self.setNetworkActivityIndicatorVisible(false) }
            
            // TODO: Handler possible errors? Or is passing them back up good?
            guard error == nil else { return runOnMainQueue { handler( .Failure(error!) ) } }
            guard let records = records else {
                return runOnMainQueue {
                    handler( .Failure( Error.UnableToAccessReturnedRecordsOfType(ScheduleDay.recordType) ) )
                }
            }
            
            let scheduleDays = records.map { ScheduleDay(record: $0) }
            
            runOnMainQueue { handler( .Success(scheduleDays) ) }
        }
    }
    
    
    
    /// Handler executes on main thread.
    func fetchScheduleDayForER(er: ER, onDate date: NSDate, handler: (ScheduleDayFetchResult)->() ) {
        let predicate = NSPredicate(
            format: "er == %@ AND date >= %@ AND date < %@",
            er.recordID, date.beginningOfDay, date.endOfDay
        )
        let query = CKQuery(recordType: ScheduleDay.recordType, predicate: predicate)
        query.sortDescriptors = [ NSSortDescriptor(key: "modificationDate", ascending: true) ]
        
        setNetworkActivityIndicatorVisible(true)
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            runOnMainQueue { self.setNetworkActivityIndicatorVisible(false) }
            
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
            
            let scheduleDay = ScheduleDay(record: record)
            
            runOnMainQueue { handler( .Success(scheduleDay) ) }
        }
    }
    
    // MARK: Creation
    
    func createScheduleDayForER(er: ER, onDate date: NSDate) -> ScheduleDay {
        let scheduleDayRecord = CKRecord(recordType: ScheduleDay.recordType)
        
        scheduleDayRecord["er"] = er.asCKReferenceWithAction(.None)
        scheduleDayRecord["date"] = date
        
        let scheduleDay = ScheduleDay(record: scheduleDayRecord)
        return scheduleDay
    }
    
    // MARK: Saving
    
    enum ScheduleDaySaveResult {
        case Failure(ErrorType)
        case Success(ScheduleDay)
    }
    
    /// Handler executes on main thread.
    func saveScheduleDay(scheduleDay: ScheduleDay, handler: (ScheduleDaySaveResult)->() ) {
        
        let record = scheduleDay.asCKRecord
        
        setNetworkActivityIndicatorVisible(true)
        
        publicDatabase.saveRecord(record) { record, error in
            runOnMainQueue { self.setNetworkActivityIndicatorVisible(false) }
            
            guard error == nil else { return runOnMainQueue { handler( .Failure(error!) ) } }
            guard let record = record else {
                return runOnMainQueue {
                    handler( .Failure( Error.UnableToAccessReturnedRecordsOfType(ScheduleDay.recordType) ) )
                }
            }
            
            let scheduleDay = ScheduleDay(record: record)
            
            runOnMainQueue { handler( .Success(scheduleDay) ) }
        }
    }
}