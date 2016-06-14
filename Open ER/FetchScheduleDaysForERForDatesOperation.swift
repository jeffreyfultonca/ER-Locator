//
//  FetchScheduleDaysForERForDatesOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class FetchScheduleDaysForERForDatesOperation: AsyncOperation, CloudKitRecordableOperationable {
    
    // MARK: - Stored Properties
    private let cloudDatabase: CKDatabase
    private let er: ER
    private let dates: [NSDate]
    
    private var queue = NSOperationQueue()
    
    var result: CloudKitRecordableFetchResult<ScheduleDay> = .Failure(Error.OperationNotComplete)
    override func cancel() {
        result = .Failure(Error.OperationCancelled)
        super.cancel()
    }
    
    // MARK: - Lifecycle
    
    init(
        cloudDatabase: CKDatabase,
        er: ER,
        dates: [NSDate],
        priority: CloudKitRecordableFetchRequestPriority = .Normal)
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
        fromExistingOperation existingOperation: FetchScheduleDaysForERForDatesOperation,
        withPriority priority: CloudKitRecordableFetchRequestPriority)
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
