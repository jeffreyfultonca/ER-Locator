//
//  FetchCloudKitRecordableOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-09.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

enum FetchCloudKitRecordableResult<T: CloudKitRecordable> {
    case Failure(ErrorType)
    case Success([T])
}

/**
 Generic NSOperation subclass used to concurrently fetch CKRecords from a CloudKit database and parse them into CloudKitRecordable objects.
 
 Parameters: See CKQueryOperation documentation as all paramaters correspond.
 */
class FetchCloudKitRecordableOperation<T: CloudKitRecordable>: AsyncOperation {
    
    // MARK: - Stored Properties
    private let cloudDatabase: CKDatabase
    private let recordZoneID: CKRecordZoneID?
    private let predicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]?
    private let resultsLimit: Int?
    
    // Cancel CloudKit Request after this interval.
    var timeoutIntervalInSeconds: Double = 60
    
    var result: FetchCloudKitRecordableResult<T> = .Failure(Error.OperationNotComplete)
    
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
    
    // MARK: - Helpers
    
    func completeOperationWithResult(result: FetchCloudKitRecordableResult<T>) {
        self.result = result
        completeOperation()
    }
}
