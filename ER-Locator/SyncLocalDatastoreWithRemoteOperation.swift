//
//  SyncLocalDatastoreWithRemoteOperation.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-10.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class SyncLocalDatastoreWithRemoteOperation: AsyncOperation {
    
    // MARK: - Dependencies
    let cloudDatabase: CKDatabase
    var persistenceProvider: PersistenceProviding
    
    // MARK: - Stored Properties
    private var queue = NSOperationQueue()
    
    var result: SyncLocalDatastoreWithRemoteResult = .Failure(Error.OperationNotComplete)
    override func cancel() {
        result = .Failure(Error.OperationCancelled)
        super.cancel()
    }
    
    // MARK: - Lifecycle
    
    init(cloudDatabase: CKDatabase, persistenceProvider: PersistenceProviding) {
        self.cloudDatabase = cloudDatabase
        self.persistenceProvider = persistenceProvider
    }
    
    override func main() {
        let showNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: true)
        
        // ERs modified  since last sync
        let ersMostRecentlyModifiedAt = persistenceProvider.ersMostRecentlyModifiedAt ?? NSDate.distantPast()
        let ersModifiedSinceDatePredicate = NSPredicate(format: "modificationDate > %@", ersMostRecentlyModifiedAt)
        let fetchERs = FetchOperation<ER>(
            cloudDatabase: cloudDatabase,
            predicate: ersModifiedSinceDatePredicate
        )
        
        // Today's ScheduleDays modified since last sync
        // TODO: Limit modificationDate to Today...
        let todaysScheduleDaysMostRecentlyModifiedAt = persistenceProvider.todaysScheduleDays.mostRecentlyModifiedAt ?? NSDate.distantPast()
        let todaysScheduleDaysModifiedSinceDatePredicate = NSPredicate(format: "modificationDate > %@ && date == %@", todaysScheduleDaysMostRecentlyModifiedAt, NSDate().beginningOfDay)
        let fetchScheduleDays = FetchOperation<ScheduleDay>(
            cloudDatabase: cloudDatabase,
            predicate: todaysScheduleDaysModifiedSinceDatePredicate
        )
        
        let hideNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: false)
        
        let completion = NSBlockOperation {
            if case .Success(let modifiedERs) = fetchERs.result where modifiedERs.count > 0 {
                let existingERs = self.persistenceProvider.ers
                self.persistenceProvider.ers = existingERs.union(modifiedERs)
                self.persistenceProvider.ersMostRecentlyModifiedAt = modifiedERs.mostRecentlyModifiedAt
            }
            
            if case .Success(let modifiedScheduleDays) = fetchScheduleDays.result where modifiedScheduleDays.count > 0 {
                let existingScheduleDays = self.persistenceProvider.todaysScheduleDays
                self.persistenceProvider.todaysScheduleDays = existingScheduleDays.union(modifiedScheduleDays).scheduledToday
            }
            
            switch (fetchERs.result, fetchScheduleDays.result) {
            case (.Failure(let error), .Failure):
                self.completeOperationWithResult( .Failure(error) )
                
            case (.Success, .Failure(let error)):
                self.completeOperationWithResult( .Failure(error) )
                
            case (.Failure(let error), .Success):
                self.completeOperationWithResult( .Failure(error) )
                
            case (.Success(let ers), .Success(let scheduleDays)):
                let noData = ers.isEmpty && scheduleDays.isEmpty
                self.completeOperationWithResult( noData ? .NoData : .NewData )
            }
        }
        
        // Dependencies
        fetchERs.addDependency(showNetworkActivityIndicator)
        fetchScheduleDays.addDependency(showNetworkActivityIndicator)
        
        hideNetworkActivityIndicator.addDependency(fetchERs)
        hideNetworkActivityIndicator.addDependency(fetchScheduleDays)
        
        completion.addDependency(hideNetworkActivityIndicator)
        completion.addDependency(fetchERs)
        completion.addDependency(fetchScheduleDays)
        
        // Start operations
        queue.addOperations([
            showNetworkActivityIndicator,
            fetchERs,
            fetchScheduleDays,
            hideNetworkActivityIndicator,
            completion
        ], waitUntilFinished: false)
    }
    
    private func completeOperationWithResult(result: SyncLocalDatastoreWithRemoteResult) {
        self.result = result
        completeOperation()
    }
}