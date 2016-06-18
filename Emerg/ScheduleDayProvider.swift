//
//  ScheduleDayProvider.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

// MARK: - ScheduleDayProviding Protocol

protocol ScheduleDayProviding {
    
    /// Synchronous access to all known Emergs. Generally from an in-memory store or perhaps local storage.
    var todaysScheduleDays: [ScheduleDay] { get }
    
    /// Clear in memory cache of ScheduleDays. This cache is used for the Scheduler only and does not affect the `todaysScheduleDay` property.
    func clearInMemoryCache()
    
    func fetchScheduleDayFromCache(for _: Emerg, on: NSDate) -> ScheduleDay?
    
    func fetchScheduleDays(
        for _: Emerg,
        on: [NSDate],
        resultQueue: NSOperationQueue,
        result: (FetchResult<ScheduleDay>)->()
    ) -> ReprioritizableRequest
    
    func save(
        scheduleDay: ScheduleDay,
        resultQueue: NSOperationQueue,
        result: (SaveResult<ScheduleDay>)->()
    )
    
    func makeScheduleDay(for _: Emerg, on: NSDate) -> ScheduleDay
}

// MARK: - Default Singleton Implementation

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
    func clearInMemoryCache() { inMemoryScheduleDayCache.removeAll() }
    
    // MARK: - Fetching
    
    /**
     Synchronously fetch ScheduleDay from in-memory cache.
     */
    func fetchScheduleDayFromCache(for emerg: Emerg, on date: NSDate) -> ScheduleDay? {
        let key = emerg.hashValue.description + date.hashValue.description
        return inMemoryScheduleDayCache[key]
    }
    
    /**
     Asynchronously fetch ScheduleDay from CloudKit.
     */
    func fetchScheduleDays(
        for emerg: Emerg,
        on dates: [NSDate],
        resultQueue: NSOperationQueue,
        result: (FetchResult<ScheduleDay>) -> ())
        -> ReprioritizableRequest
    {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let fetchScheduleDaysForEmergForDates = FetchScheduleDaysForEmergForDatesOperation(
            cloudDatabase: cloudDatabase,
            er: emerg,
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
                        self.makeScheduleDay(for: emerg, on: requestedDate)
                    
                    scheduleDaysToReturn.append(scheduleDay)
                    let key = emerg.hashValue.description + scheduleDay.date.hashValue.description
                    self.inMemoryScheduleDayCache[key] = scheduleDay
                }
                
                resultQueue.addOperationWithBlock { result( .Success(scheduleDaysToReturn) ) }
            }
        }
        
        workQueue.addOperation(fetchScheduleDaysForEmergForDates)
        
        return FetchRequest(operation: fetchScheduleDaysForEmergForDates, queue: workQueue)
    }
    
    // MARK: - Saving
    
    func save(
        scheduleDay: ScheduleDay,
        resultQueue: NSOperationQueue,
        result: (SaveResult<ScheduleDay>) -> ())
    {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let showNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: true)
        
        let saveScheduleDaysOperation = SaveOperation(
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
    
    func makeScheduleDay(for emerg: Emerg, on date: NSDate) -> ScheduleDay {
        let scheduleDayRecord = CKRecord(recordType: ScheduleDay.recordType)
        
        scheduleDayRecord["er"] = CKReference(record: emerg.record, action: .None)
        scheduleDayRecord["date"] = date
        
        let scheduleDay = ScheduleDay(record: scheduleDayRecord)
        
        return scheduleDay
    }
}
