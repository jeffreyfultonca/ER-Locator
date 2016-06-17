//
//  ScheduleDayProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

protocol ScheduleDayProviding {
    var todaysScheduleDays: [ScheduleDay] { get }
    
    func clearCache()
    
    func fetchScheduleDayFromCacheForEmerg(er: Emerg, onDate: NSDate) -> ScheduleDay?
    
    func fetchScheduleDaysForEmerg(
        er: Emerg,
        forDates: [NSDate],
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<ScheduleDay>)->()
    ) -> CloudKitRecordableFetchRequestable
    
    func saveScheduleDay(
        scheduleDay: ScheduleDay,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableSaveResult<ScheduleDay>)->()
    )
    
    func createScheduleDayForEmerg(er: Emerg, onDate date: NSDate) -> ScheduleDay
}

typealias InMemoryScheduleDayCache = [String: ScheduleDay]

class ScheduleDayProvider: ScheduleDayProviding {
    static let sharedInstance = ScheduleDayProvider()
    
    // `private` to enforce singleton.
    private init() {
        // Fetch requests are batched by month. There can only be two months displayed on screen simultaneously, any more than that should be set to lower priority if queued.
        workQueue.maxConcurrentOperationCount = 2
    }
    
    // MARK: - Dependencies
    var persistenceProvider: PersistenceProviding = PersistenceProvider.sharedInstance
    
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
     Synchronously fetch ScheduleDay from in-memory cache.
     */
    
    func fetchScheduleDayFromCacheForEmerg(er: Emerg, onDate date: NSDate) -> ScheduleDay? {
        let key = er.hashValue.description + date.hashValue.description
        return inMemoryScheduleDayCache[key]
    }
    
    /**
     Asynchronously fetch ScheduleDay from CloudKit.
     */
    func fetchScheduleDaysForEmerg(
        er: Emerg,
        forDates dates: [NSDate],
                 resultQueue: NSOperationQueue,
                 result: (CloudKitRecordableFetchResult<ScheduleDay>) -> ())
        -> CloudKitRecordableFetchRequestable
    {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let fetchScheduleDaysForEmergForDates = FetchScheduleDaysForEmergForDatesOperation(
            cloudDatabase: cloudDatabase,
            er: er,
            dates: dates,
            priority: .High
        )
        
        fetchScheduleDaysForEmergForDates.completionBlock = {
            switch fetchScheduleDaysForEmergForDates.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let scheduleDaysFetched):
                // Add ScheduleDay record to cache for each requested date.
                
                var scheduleDaysToReturn = [ScheduleDay]()
                
                dates.forEach { requestedDate in
                    // Create ScheduleDay (closed) if none returned and add to cache for each
                    let scheduleDay = scheduleDaysFetched.filter({ $0.date == requestedDate }).first ??
                        self.createScheduleDayForEmerg(er, onDate: requestedDate)
                    scheduleDaysToReturn.append(scheduleDay)
                    let key = er.hashValue.description + scheduleDay.date.hashValue.description
                    self.inMemoryScheduleDayCache[key] = scheduleDay
                }
                
                resultQueue.addOperationWithBlock { result( .Success(scheduleDaysToReturn) ) }
            }
        }
        
        workQueue.addOperation(fetchScheduleDaysForEmergForDates)
        
        return CloudKitRecordableFetchRequest(operation: fetchScheduleDaysForEmergForDates, queue: workQueue)
    }
    
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
    
    func createScheduleDayForEmerg(er: Emerg, onDate date: NSDate) -> ScheduleDay {
        let scheduleDayRecord = CKRecord(recordType: ScheduleDay.recordType)
        
        scheduleDayRecord["er"] = CKReference(record: er.record, action: .None)
        scheduleDayRecord["date"] = date
        
        let scheduleDay = ScheduleDay(record: scheduleDayRecord)
        
        return scheduleDay
    }
}
