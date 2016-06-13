//
//  FetchScheduleDaysForEROnDateOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class FetchScheduleDaysForEROnDateOperation: AsyncOperation, CloudKitRecordableOperationable {
    
    // MARK: - Stored Properties
    private let inMemoryScheduleDayCache: InMemoryScheduleDayCache
    private let cloudDatabase: CKDatabase
    private let er: ER
    private let date: NSDate
    
    private var queue = NSOperationQueue()
    
    var result: CloudKitRecordableFetchResult<ScheduleDay> = .Failure(Error.OperationNotComplete)
    
    // MARK: - Lifecycle
    
    init(
        inMemoryScheduleDayCache: InMemoryScheduleDayCache,
        cloudDatabase: CKDatabase,
        er: ER,
        date: NSDate,
        priority: CloudKitRecordableFetchRequestPriority = .Normal)
    {
        self.inMemoryScheduleDayCache = inMemoryScheduleDayCache
        self.cloudDatabase = cloudDatabase
        self.er = er
        self.date = date
        
        super.init()
        
        // TODO: This is duplicated between all the CloudKitRecordableOperationable classes. Move somewhere common?
        switch priority {
        case .Normal:
            qualityOfService = .Utility
            queuePriority = .Normal
            
        case .High:
            qualityOfService = .UserInitiated
            queuePriority = .High
        }
    }
    
    required convenience init(
        fromExistingOperation existingOperation: FetchScheduleDaysForEROnDateOperation,
        withPriority priority: CloudKitRecordableFetchRequestPriority)
    {
        self.init(
            inMemoryScheduleDayCache: existingOperation.inMemoryScheduleDayCache,
            cloudDatabase: existingOperation.cloudDatabase,
            er: existingOperation.er,
            date: existingOperation.date,
            priority: priority
        )
    }
    
    override func main() {
        // Check in-memory cache first
        let key = er.hashValue.description + date.hashValue.description
        if let scheduleDay = inMemoryScheduleDayCache[key] {
            self.completeOperationWithResult( .Success([scheduleDay]) )
            return
        }
        
        // Otherwise fetch from CloudKit
        
        let showNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: true)
        
        let predicate = NSPredicate(
            format: "er == %@ AND date >= %@ AND date < %@",
            er.recordID, date.beginningOfDay, date.endOfDay
        )
        
        let sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        
        let fetchScheduleDays = CloudKitRecordableFetchOperation<ScheduleDay>(
            cloudDatabase: cloudDatabase,
            predicate: predicate,
            sortDescriptors: sortDescriptors
        )
        
        let hideNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: false)
        
        fetchScheduleDays.completionBlock = {
            switch fetchScheduleDays.result {
            case .Failure(let error):
                self.completeOperationWithResult( .Failure(error) )
            
            case .Success(let scheduleDays):
                self.completeOperationWithResult( .Success(scheduleDays) )
            }
        }
        
        // Dependencies
        fetchScheduleDays.addDependency(showNetworkActivityIndicator)
        hideNetworkActivityIndicator.addDependency(fetchScheduleDays)
        
        // Start operations
        queue.addOperations([
            showNetworkActivityIndicator,
            fetchScheduleDays,
            hideNetworkActivityIndicator
        ], waitUntilFinished: false)
    }
    
    private func completeOperationWithResult(result: CloudKitRecordableFetchResult<ScheduleDay>) {
        self.result = result
        completeOperation()
    }
}
