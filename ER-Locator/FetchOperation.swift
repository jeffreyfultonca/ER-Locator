//
//  FetchOperation.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-09.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

/**
 Generic NSOperation subclass used to concurrently fetch CKRecords from a CloudKit database and parse them into CloudKitModel objects.
 
 Parameters: See CKQueryOperation documentation as all paramaters correspond.
 */
class FetchOperation<T: CloudKitModel>: AsyncOperation {
    
    // MARK: - Stored Properties
    private let cloudDatabase: CKDatabase
    private let recordZoneID: CKRecordZoneID?
    private let predicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]?
    private let resultsLimit: Int?
    
    // Cancel CloudKit Request after this interval.
    var timeoutIntervalInSeconds: Double = 30
    
    var result: FetchResult<T> = .failure(SnowError.operationNotComplete)
    
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
                return self.completeOperation(.failure(error!) )
            }
            
            let cloudKitRecordables = fetchedRecords.map { T(record: $0) }
            self.completeOperation(.success(cloudKitRecordables) )
        }
        
        queryOperation.start()
        
        // Roll your own timeout... it works.
        delay(inSeconds: self.timeoutIntervalInSeconds) {
            // Timeout operation
            self.result = .failure(SnowError.operationTimedOut)
            queryOperation.cancel()
        }
    }
    
    // MARK: Helpers
    
    private func completeOperation(_ result: FetchResult<T>) {
        self.result = result
        completeOperation()
    }
}

// MARK: - Result

enum FetchResult<T: CloudKitModel> {
    case failure(Error)
    case success([T])
}

// MARK: - Request

enum RequestPriority {
    case normal
    case high
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
    private var queue: OperationQueue
    
    var finished: Bool {
        return operation.finished
    }
    
    var priority: RequestPriority = .normal {
        didSet(oldPriority) {
            guard priority != oldPriority else { return }
            guard operation.executing == false else { return }
            
            let newOperation = T(from: operation, priority: priority)
            
            operation.cancel()
            operation = newOperation
            if let operation = operation as? Operation {
                queue.addOperation(operation)
            }
        }
    }
    
    init(operation: T, queue: OperationQueue) {
        self.operation = operation
        self.queue = queue
    }
    
    func cancel() {
        operation.cancel()
    }
}

