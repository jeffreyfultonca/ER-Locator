//
//  SaveOperation.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class SaveOperation<T: CloudKitModel>: AsyncOperation {
    
    // MARK: - Stored Properties
    let cloudDatabase: CKDatabase
    let recordsToSave: [T]
    
    var result: SaveResult<T> = .Failure(Error.OperationNotComplete)
    
    init(cloudDatabase: CKDatabase, recordsToSave: [T]) {
        self.cloudDatabase = cloudDatabase
        self.recordsToSave = recordsToSave
        
        super.init()
    }
    
    override func main() {
        let ckRecords = recordsToSave.map { $0.record }
        
        let modifyRecordsOperation = CKModifyRecordsOperation(
            recordsToSave: ckRecords,
            recordIDsToDelete: nil
        )
        
        modifyRecordsOperation.database = cloudDatabase
        modifyRecordsOperation.savePolicy = .ChangedKeys
        
        modifyRecordsOperation.modifyRecordsCompletionBlock = { modifiedRecords, recordIDs, error in
            guard error == nil else {
                return self.completeOperation(.Failure(error!))
            }
            
            guard let modifiedRecords = modifiedRecords else {
                return self.completeOperation(.Failure(Error.UnableToAccessReturnedRecordsOfType(T.recordType)))
            }
            
            let cloudKitRecordables = modifiedRecords.map { T(record: $0) }
            self.completeOperation(.Success(cloudKitRecordables))
        }
        
        modifyRecordsOperation.start()
    }
    
    // MARK: Helpers
    
    private func completeOperation(result: SaveResult<T>) {
        self.result = result
        completeOperation()
    }
}

// MARK: - Result

enum SaveResult<T: CloudKitModel> {
    case Failure(ErrorType)
    case Success([T])
}

