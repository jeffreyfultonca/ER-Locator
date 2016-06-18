//
//  FetchScheduleDaysForEmergForDatesOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class FetchScheduleDaysForEmergForDatesOperation: AsyncOperation, ReprioritizableOperation {
    
    // MARK: - Stored Properties
    private let cloudDatabase: CKDatabase
    private let er: Emerg
    private let dates: [NSDate]
    
    private var queue = NSOperationQueue()
    
    var result: FetchResult<ScheduleDay> = .Failure(Error.OperationNotComplete)
    override func cancel() {
        result = .Failure(Error.OperationCancelled)
        super.cancel()
    }
    
    // MARK: - Lifecycle
    
    init(
        cloudDatabase: CKDatabase,
        er: Emerg,
        dates: [NSDate],
        priority: RequestPriority = .Normal)
    {
        self.cloudDatabase = cloudDatabase
        self.er = er
        self.dates = dates
        
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
        from existingOperation: FetchScheduleDaysForEmergForDatesOperation,
        priority: RequestPriority)
    {
        self.init(
            cloudDatabase: existingOperation.cloudDatabase,
            er: existingOperation.er,
            dates: existingOperation.dates,
            priority: priority
        )
    }
    
    override func main() {
        let showNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: true)
        
        let predicate = NSPredicate(format: "er == %@ AND date IN %@", er.recordID, dates)
        let sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        
        let fetchScheduleDays = FetchOperation<ScheduleDay>(
            cloudDatabase: cloudDatabase,
            predicate: predicate,
            sortDescriptors: sortDescriptors
        )
        
        let hideNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: false)
        
        fetchScheduleDays.completionBlock = {
            switch fetchScheduleDays.result {
            case .Failure(let error):
                self.completeOperation(.Failure(error))
            
            case .Success(let scheduleDays):
                self.completeOperation(.Success(scheduleDays))
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
    
    private func completeOperation(result: FetchResult<ScheduleDay>) {
        self.result = result
        completeOperation()
    }
}
