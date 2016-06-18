//
//  FetchOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-09.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

/**
 Generic NSOperation subclass used to concurrently fetch CKRecords from a CloudKit database and parse them into CloudKitModal objects.
 
 Parameters: See CKQueryOperation documentation as all paramaters correspond.
 */
class FetchOperation<T: CloudKitModal>: AsyncOperation {
    
    // MARK: - Stored Properties
    private let cloudDatabase: CKDatabase
    private let recordZoneID: CKRecordZoneID?
    private let predicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]?
    private let resultsLimit: Int?
    
    // Cancel CloudKit Request after this interval.
    var timeoutIntervalInSeconds: Double = 30
    
    var result: FetchResult<T> = .Failure(Error.OperationNotComplete)
    
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
                return self.completeOperation(.Failure(error!) )
            }
            
            let cloudKitRecordables = fetchedRecords.map { T(record: $0) }
            self.completeOperation(.Success(cloudKitRecordables) )
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
    
    private func completeOperation(result: FetchResult<T>) {
        self.result = result
        completeOperation()
    }
}

// MARK: - Result

enum FetchResult<T: CloudKitModal> {
    case Failure(ErrorType)
    case Success([T])
}

// MARK: - Request

enum RequestPriority {
    case Normal
    case High
}

protocol ReprioritizableOperation {
    var finished: Bool { get }
    var executing: Bool { get }
    
    init(from existingOperation: Self, priority: RequestPriority)
    
    func cancel()
}

protocol ReprioritizableRequest {
    var finished: Bool { get }
    var priority: RequestPriority { get set }
}

class FetchRequest<T: ReprioritizableOperation>: ReprioritizableRequest {
    private var operation: T
    private var queue: NSOperationQueue
    
    var finished: Bool {
        return operation.finished
    }
    
    var priority: RequestPriority = .Normal {
        didSet(oldPriority) {
            guard priority != oldPriority else { return }
            guard operation.executing == false else { return }
            
            let newOperation = T(from: operation, priority: priority)
            
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

