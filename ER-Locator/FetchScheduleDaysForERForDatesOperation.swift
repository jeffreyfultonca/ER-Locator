//
//  FetchScheduleDaysForERForDatesOperation.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class FetchScheduleDaysForERForDatesOperation: AsyncOperation, ReprioritizableOperation {
    
    // MARK: - Stored Properties
    private let cloudDatabase: CKDatabase
    private let er: ER
    private let dates: [Date]
    
    private var queue = OperationQueue()
    
    var result: FetchResult<ScheduleDay> = .failure(SnowError.operationNotComplete)
    override func cancel() {
        result = .failure(SnowError.operationCancelled)
        super.cancel()
    }
    
    // MARK: - Lifecycle
    
    init(
        cloudDatabase: CKDatabase,
        er: ER,
        dates: [Date],
        priority: RequestPriority = .normal)
    {
        self.cloudDatabase = cloudDatabase
        self.er = er
        self.dates = dates
        
        super.init()
        
        // TODO: This is duplicated between all the CloudKitRecordableOperationable classes. Move somewhere common?
        switch priority {
        case .normal:
            qualityOfService = .utility
            queuePriority = .normal
            
        case .high:
            qualityOfService = .userInitiated
            queuePriority = .high
        }
    }
    
    required convenience init(
        from existingOperation: FetchScheduleDaysForERForDatesOperation,
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
            case .failure(let error):
                self.completeOperation(.failure(error))
            
            case .success(let scheduleDays):
                self.completeOperation(.success(scheduleDays))
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
    
    private func completeOperation(_ result: FetchResult<ScheduleDay>) {
        self.result = result
        completeOperation()
    }
}
