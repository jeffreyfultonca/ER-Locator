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
        workQueue.maxConcurrentOperationCount = 1 // Approximately one 5.5 inch iPhone screen worth.
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
     Synchronously fetch ScheduleDay from in-memory cache.
     */
    
    func fetchScheduleDayFromCacheForER(er: ER, onDate date: NSDate) -> ScheduleDay? {
        let key = er.hashValue.description + date.hashValue.description
        return inMemoryScheduleDayCache[key]
    }
    
    /**
     Asynchronously fetch ScheduleDay from CloudKit.
     */
    func fetchScheduleDaysForER(
        er: ER,
        forDates dates: [NSDate],
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<ScheduleDay>) -> ())
        -> CloudKitRecordableFetchRequestable
    {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let fetchScheduleDaysForERForDates = FetchScheduleDaysForERForDatesOperation(
            cloudDatabase: cloudDatabase,
            er: er,
            dates: dates,
            priority: .High
        )
        
        fetchScheduleDaysForERForDates.completionBlock = {
            switch fetchScheduleDaysForERForDates.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let scheduleDays):
                // Add ScheduleDay record to cache for each requested date.
                
                dates.forEach { requestedDate in
                    // Create ScheduleDay (closed) if none returned and add to cache for each
                    let scheduleDay = scheduleDays.filter({ $0.date == requestedDate }).first ??
                        self.createScheduleDayForER(er, onDate: requestedDate)
                    let key = er.hashValue.description + scheduleDay.date.hashValue.description
                    self.inMemoryScheduleDayCache[key] = scheduleDay
                }
                
                resultQueue.addOperationWithBlock { result( .Success(scheduleDays) ) }
            }
        }

        workQueue.addOperation(fetchScheduleDaysForERForDates)
        
        return CloudKitRecordableFetchRequest(operation: fetchScheduleDaysForERForDates, queue: workQueue)
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
    
    func createScheduleDayForER(er: ER, onDate date: NSDate) -> ScheduleDay {
        let scheduleDayRecord = CKRecord(recordType: ScheduleDay.recordType)
        
        scheduleDayRecord["er"] = er.asCKReferenceWithAction(.None)
        scheduleDayRecord["date"] = date
        
        let scheduleDay = ScheduleDay(record: scheduleDayRecord)
        
        return scheduleDay
    }
}
