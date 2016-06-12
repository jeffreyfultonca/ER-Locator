//
//  FetchScheduleDaysForEROnDateOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-12.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class FetchScheduleDaysForEROnDateOperation: AsyncOperation, CloudKitRecordableOperationable {
    
    // MARK: - Dependencies
    let cloudDatabase: CKDatabase
    
    // MARK: - Stored Properties
    private let er: ER
    private let date: NSDate
    
    private var queue = NSOperationQueue()
    
    var result: CloudKitRecordableFetchResult<ScheduleDay> = .Failure(Error.OperationNotComplete)
    
    // MARK: - Lifecycle
    
    init(cloudDatabase: CKDatabase, er: ER, date: NSDate) {
        self.cloudDatabase = cloudDatabase
        self.er = er
        self.date = date
    }
    
    required convenience init(fromExistingOperation existingOperation: FetchScheduleDaysForEROnDateOperation) {
        self.init(
            cloudDatabase: existingOperation.cloudDatabase,
            er: existingOperation.er,
            date: existingOperation.date
        )
    }
    
    override func main() {
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
