//
//  ScheduleDayService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

typealias InMemoryScheduleDayCache = [String: ScheduleDay]

class ScheduleDayService: ScheduleDayProvider {
    static let sharedInstance = ScheduleDayService()
    
    // `private` to enforce singleton.
    private init() {
        workQueue.maxConcurrentOperationCount = 14 // Approximately one 5.5 inch iPhone screen worth.
    }
    
    // MARK: - Dependencies
    var persistenceProvider: PersistenceProvider = PersistenceService.sharedInstance
    
    // MARK: - Stored Properties
    private let workQueue = NSOperationQueue()
    
    var todaysScheduleDays: [ScheduleDay] {
        return Array(persistenceProvider.todaysScheduleDays)
    }
    
    // In-memory cache for used with Scheduler only
    private var inMemoryScheduleDayCache = InMemoryScheduleDayCache()
    func clearCache() { inMemoryScheduleDayCache.removeAll() }
    
    // MARK: - Fetching
    /**
     Asynchronously fetch from cache falling back to CloudKit network query.
     */
    func fetchScheduleDaysForER(
        er: ER,
        onDate date: NSDate,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<ScheduleDay>) -> ())
        -> CloudKitRecordableFetchRequestable
    {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let fetchScheduleDaysForEROnDate = FetchScheduleDaysForEROnDateOperation(
            inMemoryScheduleDayCache: inMemoryScheduleDayCache,
            cloudDatabase: cloudDatabase,
            er: er,
            date: date,
            priority: .High
        )
        
        fetchScheduleDaysForEROnDate.completionBlock = {
            switch fetchScheduleDaysForEROnDate.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let scheduleDays):
                // Create ScheduleDay (closed) if none returned and add to cache
                let scheduleDay = scheduleDays.first ?? self.createScheduleDayForER(er, onDate: date)
                let key = er.hashValue.description + scheduleDay.date.hashValue.description
                self.inMemoryScheduleDayCache[key] = scheduleDay
                
                resultQueue.addOperationWithBlock { result( .Success(scheduleDays) ) }
            }
        }

        workQueue.addOperation(fetchScheduleDaysForEROnDate)
        
        return CloudKitRecordableFetchRequest(operation: fetchScheduleDaysForEROnDate, queue: workQueue)
    }
    
    //        func preFetchAndUpdateCellsSurroundingIndexPath(indexPath: NSIndexPath) {
    //
    //            // Get dates padded around indexPath date for batching purposes.
    //
    //            let centerDate = dateForIndexPath(indexPath)
    //            let paddingDays = NSTimeInterval(60 * 60 * 24 * 15)
    //            let startDay = Day(date: centerDate.dateByAddingTimeInterval(-paddingDays) )
    //            let endDay = Day(date: centerDate.dateByAddingTimeInterval(paddingDays) )
    //
    //            let dates = startDay...endDay
    //
    //
    //
    //            // Prevent duplicate network requests
    //            //        self.datesRequested.unionInPlace(dates)
    //
    //            // Fetch from CloudKit
    //        }

    
    // MARK: - Saving
    
    func saveScheduleDay(
        scheduleDay: ScheduleDay,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableSaveResult<ScheduleDay>) -> ())
    {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let showNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: true)
        
        let saveScheduleDaysOperation = CloudKitRecordableSaveOperation(
            cloudDatabase: cloudDatabase,
            recordsToSave: [scheduleDay]
        )
        
        let hideNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: false)
        
        saveScheduleDaysOperation.completionBlock = {
            switch saveScheduleDaysOperation.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let scheduleDays):
                resultQueue.addOperationWithBlock { result( .Success(scheduleDays) ) }
            }
        }
        
        // Dependencies
        
        saveScheduleDaysOperation.addDependency(showNetworkActivityIndicator)
        hideNetworkActivityIndicator.addDependency(saveScheduleDaysOperation)
        
        // Start operations
        
        workQueue.addOperations([
            showNetworkActivityIndicator,
            saveScheduleDaysOperation,
            hideNetworkActivityIndicator
        ], waitUntilFinished: false)
    }
    
    // MARK: - Creating
    
    func createScheduleDayForER(er: ER, onDate date: NSDate) -> ScheduleDay {
        let scheduleDayRecord = CKRecord(recordType: ScheduleDay.recordType)
        
        scheduleDayRecord["er"] = er.asCKReferenceWithAction(.None)
        scheduleDayRecord["date"] = date
        
        let scheduleDay = ScheduleDay(record: scheduleDayRecord)
        
        return scheduleDay
    }
}
