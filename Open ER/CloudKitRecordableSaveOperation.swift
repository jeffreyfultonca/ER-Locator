//
//  CloudKitRecordableSaveOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class CloudKitRecordableSaveOperation<T: CloudKitRecordable>: AsyncOperation {
    
    // MARK: - Stored Properties
    let cloudDatabase: CKDatabase
    let recordsToSave: [T]
    
    var result: CloudKitRecordableSaveResult<T> = .Failure(Error.OperationNotComplete)
    
    init(cloudDatabase: CKDatabase, recordsToSave: [T]) {
        self.cloudDatabase = cloudDatabase
        self.recordsToSave = recordsToSave
        
        super.init()
    }
    
    override func main() {
        let ckRecords = recordsToSave.map { $0.asCKRecord }
        
        let modifyRecordsOperation = CKModifyRecordsOperation(
            recordsToSave: ckRecords,
            recordIDsToDelete: nil
        )
        
        modifyRecordsOperation.database = cloudDatabase
        modifyRecordsOperation.savePolicy = .ChangedKeys
        
        modifyRecordsOperation.modifyRecordsCompletionBlock = { modifiedRecords, recordIDs, error in
            guard error == nil else {
                return self.completeOperationWithResult( .Failure(error!) )
            }
            
            guard let modifiedRecords = modifiedRecords else {
                return self.completeOperationWithResult( .Failure(Error.UnableToAccessReturnedRecordsOfType(T.recordType)) )
            }
            
            let cloudKitRecordables = modifiedRecords.map { T(record: $0) }
            self.completeOperationWithResult( .Success(cloudKitRecordables) )
        }
        
        modifyRecordsOperation.start()
    }
    
    // MARK: Helpers
    
    private func completeOperationWithResult(result: CloudKitRecordableSaveResult<T>) {
        self.result = result
        completeOperation()
    }
}

// MARK: - Result

enum CloudKitRecordableSaveResult<T: CloudKitRecordable> {
    case Failure(ErrorType)
    case Success([T])
}

