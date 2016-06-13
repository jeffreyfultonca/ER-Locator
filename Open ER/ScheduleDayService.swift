//
//  ScheduleDayService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class ScheduleDayService: ScheduleDayProvider {
    static let sharedInstance = ScheduleDayService()
    private init() {}  // Enforce singleton
    
    // MARK: - Dependencies
    var persistenceProvider: PersistenceProvider = PersistenceService.sharedInstance
    
    // MARK: - Stored Properties
    private let workQueue = NSOperationQueue()
    
    var todaysScheduleDays: [ScheduleDay] {
        return Array(persistenceProvider.todaysScheduleDays)
    }
    
    // In-memory cache for Scheduler only
    private var inMemoryScheduleDayCache = [NSDate: ScheduleDay]()
    
    // MARK: - Fetching
    
    func fetchScheduleDaysForER(
        er: ER,
        onDate date: NSDate,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<ScheduleDay>) -> ())
        -> CloudKitRecordableFetchRequest<FetchScheduleDaysForEROnDateOperation>
    {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let fetchScheduleDaysForEROnDate = FetchScheduleDaysForEROnDateOperation(
            cloudDatabase: cloudDatabase,
            er: er,
            date: date
        )
        
        fetchScheduleDaysForEROnDate.completionBlock = {
            switch fetchScheduleDaysForEROnDate.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let scheduleDays):
                resultQueue.addOperationWithBlock { result( .Success(scheduleDays) ) }
            }
        }
        
        workQueue.addOperation(fetchScheduleDaysForEROnDate)
        
        return CloudKitRecordableFetchRequest(operation: fetchScheduleDaysForEROnDate, queue: workQueue)
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
