//
//  ScheduleDayProvider.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

// MARK: - ScheduleDayProviding Protocol

protocol ScheduleDayProviding {
    
    /// Synchronous access to all known ERs. Generally from an in-memory store or perhaps local storage.
    var todaysScheduleDays: [ScheduleDay] { get }
    
    /// Clear in memory cache of ScheduleDays. This cache is used for the Scheduler only and does not affect the `todaysScheduleDay` property.
    func clearInMemoryCache()
    
    func fetchScheduleDayFromCache(for _: ER, on: Date) -> ScheduleDay?
    
    func fetchScheduleDays(
        for _: ER,
        on: [Date],
        resultQueue: OperationQueue,
        result: (FetchResult<ScheduleDay>)->()
    ) -> ReprioritizableRequest
    
    func save(
        _ scheduleDay: ScheduleDay,
        resultQueue: OperationQueue,
        result: (SaveResult<ScheduleDay>)->()
    )
    
    func makeScheduleDay(for _: ER, on: Date) -> ScheduleDay
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
    private let workQueue = OperationQueue()
    
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
    func fetchScheduleDayFromCache(for er: ER, on date: Date) -> ScheduleDay? {
        let key = er.hashValue.description + date.hashValue.description
        return inMemoryScheduleDayCache[key]
    }
    
    /**
     Asynchronously fetch ScheduleDay from CloudKit.
     */
    func fetchScheduleDays(
        for er: ER,
        on dates: [Date],
        resultQueue: OperationQueue,
        result: @escaping (FetchResult<ScheduleDay>) -> ())
        -> ReprioritizableRequest
    {
        let cloudDatabase = CKContainer.default().publicCloudDatabase
        let fetchScheduleDaysForERForDates = FetchScheduleDaysForERForDatesOperation(
            cloudDatabase: cloudDatabase,
            er: er,
            dates: dates,
            priority: .high
        )
        
        fetchScheduleDaysForERForDates.completionBlock = {
            switch fetchScheduleDaysForERForDates.result {
            case .failure(let error):
                resultQueue.addOperation { result( .failure(error) ) }
                
            case .success(let scheduleDaysFetched):
                // Add ScheduleDay record to cache for each requested date.
                
                var scheduleDaysToReturn = [ScheduleDay]()
                
                dates.forEach { requestedDate in
                    // Create ScheduleDay (closed) if none returned and add to cache for each
                    let scheduleDay = scheduleDaysFetched.filter({ $0.date == requestedDate }).first ??
                        self.makeScheduleDay(for: er, on: requestedDate)
                    
                    scheduleDaysToReturn.append(scheduleDay)
                    let key = er.hashValue.description + scheduleDay.date.hashValue.description
                    self.inMemoryScheduleDayCache[key] = scheduleDay
                }
                
                resultQueue.addOperation { result( .success(scheduleDaysToReturn) ) }
            }
        }
        
        workQueue.addOperation(fetchScheduleDaysForERForDates)
        
        return FetchRequest(operation: fetchScheduleDaysForERForDates, queue: workQueue)
    }
    
    // MARK: - Saving
    
    func save(
        _ scheduleDay: ScheduleDay,
        resultQueue: OperationQueue,
        result: @escaping (SaveResult<ScheduleDay>) -> ())
    {
        let cloudDatabase = CKContainer.default().publicCloudDatabase
        
        let showNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: true)
        
        let saveScheduleDaysOperation = SaveOperation(
            cloudDatabase: cloudDatabase,
            recordsToSave: [scheduleDay]
        )
        
        let hideNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: false)
        
        saveScheduleDaysOperation.completionBlock = {
            switch saveScheduleDaysOperation.result {
            case .failure(let error):
                resultQueue.addOperation { result( .failure(error) ) }
                
            case .success(let scheduleDays):
                resultQueue.addOperation { result( .success(scheduleDays) ) }
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
    
    func makeScheduleDay(for er: ER, on date: Date) -> ScheduleDay {
        let scheduleDayRecord = CKRecord(recordType: ScheduleDay.recordType)
        
        scheduleDayRecord["er"] = CKReference(record: er.record, action: .deleteSelf)
        scheduleDayRecord["date"] = date
        
        let scheduleDay = ScheduleDay(record: scheduleDayRecord)
        
        return scheduleDay
    }
}
