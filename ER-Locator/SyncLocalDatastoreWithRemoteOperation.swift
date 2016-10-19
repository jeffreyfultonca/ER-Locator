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
    private var queue = OperationQueue()
    
    var result: SyncLocalDatastoreWithRemoteResult = .failure(SnowError.operationNotComplete)
    override func cancel() {
        result = .failure(SnowError.operationCancelled)
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
        let ersMostRecentlyModifiedAt = persistenceProvider.ersMostRecentlyModifiedAt ?? Date.distantPast
        let ersModifiedSinceDatePredicate = NSPredicate(format: "modificationDate > %@", ersMostRecentlyModifiedAt)
        let fetchERs = FetchOperation<ER>(
            cloudDatabase: cloudDatabase,
            predicate: ersModifiedSinceDatePredicate
        )
        
        // Today's ScheduleDays modified since last sync
        // TODO: Limit modificationDate to Today...
        let todaysScheduleDaysMostRecentlyModifiedAt = persistenceProvider.todaysScheduleDays.mostRecentlyModifiedAt ?? Date.distantPast
        let todaysScheduleDaysModifiedSinceDatePredicate = NSPredicate(format: "modificationDate > %@ && date == %@", todaysScheduleDaysMostRecentlyModifiedAt, Date().beginningOfDay)
        let fetchScheduleDays = FetchOperation<ScheduleDay>(
            cloudDatabase: cloudDatabase,
            predicate: todaysScheduleDaysModifiedSinceDatePredicate
        )
        
        let hideNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: false)
        
        let completion = BlockOperation {
            if case .success(let modifiedERs) = fetchERs.result, modifiedERs.count > 0 {
                let existingERs = self.persistenceProvider.ers
                self.persistenceProvider.ers = existingERs.union(modifiedERs)
                self.persistenceProvider.ersMostRecentlyModifiedAt = modifiedERs.mostRecentlyModifiedAt
            }
            
            if case .success(let modifiedScheduleDays) = fetchScheduleDays.result, modifiedScheduleDays.count > 0 {
                let existingScheduleDays = self.persistenceProvider.todaysScheduleDays
                self.persistenceProvider.todaysScheduleDays = existingScheduleDays.union(modifiedScheduleDays).scheduledToday
            }
            
            switch (fetchERs.result, fetchScheduleDays.result) {
            case (.failure(let error), .failure):
                self.completeOperationWithResult( .failure(error) )
                
            case (.success, .failure(let error)):
                self.completeOperationWithResult( .failure(error) )
                
            case (.failure(let error), .success):
                self.completeOperationWithResult( .failure(error) )
                
            case (.success(let ers), .success(let scheduleDays)):
                let noData = ers.isEmpty && scheduleDays.isEmpty
                self.completeOperationWithResult( noData ? .noData : .newData )
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
    
    private func completeOperationWithResult(_ result: SyncLocalDatastoreWithRemoteResult) {
        self.result = result
        completeOperation()
    }
}
