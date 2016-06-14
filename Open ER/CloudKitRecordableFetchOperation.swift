//
//  CloudKitRecordableFetchOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-09.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

/**
 Generic NSOperation subclass used to concurrently fetch CKRecords from a CloudKit database and parse them into CloudKitRecordable objects.
 
 Parameters: See CKQueryOperation documentation as all paramaters correspond.
 */
class CloudKitRecordableFetchOperation<T: CloudKitRecordable>: AsyncOperation {
    
    // MARK: - Stored Properties
    private let cloudDatabase: CKDatabase
    private let recordZoneID: CKRecordZoneID?
    private let predicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]?
    private let resultsLimit: Int?
    
    // Cancel CloudKit Request after this interval.
    var timeoutIntervalInSeconds: Double = 30
    
    var result: CloudKitRecordableFetchResult<T> = .Failure(Error.OperationNotComplete)
    
    // MARK: - Lifecycle
    
    init(
        cloudDatabase: CKDatabase,
        recordZoneID: CKRecordZoneID? = nil,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor]? = nil,
        resultsLimit: Int? = nil)
    {
        self.cloudDatabase = cloudDatabase
        self.recordZoneID = recordZoneID
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.resultsLimit = resultsLimit
        
        super.init()
    }
    
    override func main() {
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.database = cloudDatabase
        if let resultsLimit = resultsLimit { queryOperation.resultsLimit = resultsLimit }
        
        var fetchedRecords = [CKRecord]()
        queryOperation.recordFetchedBlock = { fetchedRecords.append($0) }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else {
                return self.completeOperationWithResult( .Failure(error!) )
            }
            
            let cloudKitRecordables = fetchedRecords.map { T(record: $0) }
            self.completeOperationWithResult( .Success(cloudKitRecordables) )
        }
        
        queryOperation.start()
        
        // Roll your own timeout... it works.
        delay(inSeconds: self.timeoutIntervalInSeconds) {
            // Timeout operation
            self.result = .Failure(Error.OperationTimedOut)
            queryOperation.cancel()
        }
    }
    
    // MARK: Helpers
    
    private func completeOperationWithResult(result: CloudKitRecordableFetchResult<T>) {
        self.result = result
        completeOperation()
    }
}

// MARK: - Result

enum CloudKitRecordableFetchResult<T: CloudKitRecordable> {
    case Failure(ErrorType)
    case Success([T])
}

// MARK: - Request

enum CloudKitRecordableFetchRequestPriority {
    case Normal
    case High
}

protocol CloudKitRecordableOperationable {
    var finished: Bool { get }
    var executing: Bool { get }
    
    init(fromExistingOperation: Self, withPriority: CloudKitRecordableFetchRequestPriority)
    
    func cancel()
}

protocol CloudKitRecordableFetchRequestable {
    var finished: Bool { get }
    var priority: CloudKitRecordableFetchRequestPriority { get set }
}

class CloudKitRecordableFetchRequest<T: CloudKitRecordableOperationable>: CloudKitRecordableFetchRequestable {
    
    private var operation: T
    private var queue: NSOperationQueue
    
    var finished: Bool {
        return operation.finished
    }
    
    var priority: CloudKitRecordableFetchRequestPriority = .Normal {
        didSet(oldPriority) {
            guard priority != oldPriority else { return }
            guard operation.executing == false else { return }
            
            let newOperation = T(fromExistingOperation: operation, withPriority: priority)
            
            operation.cancel()
            operation = newOperation
            if let operation = operation as? NSOperation {
                queue.addOperation(operation)
            }
        }
    }
    
    init(operation: T, queue: NSOperationQueue) {
        self.operation = operation
        self.queue = queue
    }
    
    func cancel() {
        operation.cancel()
    }
}

