//
//  PersistenceProvider.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

// MARK: - PersistenceProviding protocol

protocol PersistenceProviding {
    
    // MARK: - Storage
    var ers: Set<ER> { get set }
    var ersMostRecentlyModifiedAt: Date? { get set }
    
    var todaysScheduleDays: Set<ScheduleDay> { get set }
    
    // MARK: - Sync
    var syncing: Bool { get }
    
    var lastSuccessSyncAt: Date? { get set }
    
    /// Update local datastore with any changes from remote datastore and report back status. i.e. Failure, NoData, NewData.
    func syncLocalDatastoreWithRemote(
        _ resultQueue: OperationQueue,
        result: ( (SyncLocalDatastoreWithRemoteResult) -> () )?
    )
    
    // Scheduler Access
    func determineSchedulerAccess(
        completionQueue: OperationQueue,
        completion: @escaping (Bool) -> Void
    )
}

enum SyncLocalDatastoreWithRemoteResult {
    case failure(Error)
    case noData
    case newData
    case syncAlreadyInProgress
}

// MARK: - PersistenceProviding singleton implementation

class PersistenceProvider: PersistenceProviding {
    static let sharedInstance = PersistenceProvider()
    private init() {} // Enforce singleton.
    
    // MARK: - Dependencies
    lazy var defaults = UserDefaults.standard
    lazy var erProvider: ERProviding = ERProvider.sharedInstance
    
    // MARK: - User Default Keys
    struct UserDefaultKey {
        
        // CloudKitRecordables
        static let ERs = "ERs"
        static let TodaysScheduleDays = "TodaysScheduleDays"
        
        static let ERsMostRecentlyModifiedAt = "ERsMostRecentlyModifiedAt"
        static let TodaysScheduleDaysMostRecentlyModifiedAt = "TodaysScheduleDaysMostRecentlyModifiedAt"
        
        // Sync
        static let LastSuccessSyncAt = "LastSuccessSyncAt"
    }
    
    // MARK: - Stored Properties
    private let syncQueue = OperationQueue()
    
    // MARK: - Storage
    
    var ers: Set<ER> {
        get {
            guard let data = defaults.object(forKey: UserDefaultKey.ERs) as? Data else { return Set<ER>() }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? Set<ER> ?? Set<ER>()
        }
        set {
            let archivedObject = NSKeyedArchiver.archivedData(withRootObject: newValue)
            defaults.set(archivedObject, forKey: UserDefaultKey.ERs)
        }
    }
    
    var ersMostRecentlyModifiedAt: Date? {
        get { return defaults.object(forKey: UserDefaultKey.ERsMostRecentlyModifiedAt) as? Date }
        set { defaults.set(newValue, forKey: UserDefaultKey.ERsMostRecentlyModifiedAt) }
    }
    
    var todaysScheduleDays: Set<ScheduleDay> {
        get {
            guard let data = defaults.object(forKey: UserDefaultKey.TodaysScheduleDays) as? Data,
                let scheduleDays = NSKeyedUnarchiver.unarchiveObject(with: data) as? Set<ScheduleDay> else
            {
                return Set<ScheduleDay>()
            }
            
            return  scheduleDays.scheduledToday
        }
        set {
            let archivedObject = NSKeyedArchiver.archivedData(withRootObject: newValue)
            defaults.set(archivedObject, forKey: UserDefaultKey.TodaysScheduleDays)
        }
    }
    
    // MARK: - Sync
    
    var syncing: Bool { return
        syncQueue.operationCount > 0
    }
    
    var lastSuccessSyncAt: Date? {
        get { return defaults.object(forKey: UserDefaultKey.LastSuccessSyncAt) as? Date }
        set { defaults.set(newValue, forKey: UserDefaultKey.LastSuccessSyncAt) }
    }
    
    func syncLocalDatastoreWithRemote(
        _ resultQueue: OperationQueue,
        result: ( (SyncLocalDatastoreWithRemoteResult) -> () )? )
    {
        // Return if sync already in progress
        guard syncing == false else {
            return resultQueue.addOperation { result?(.syncAlreadyInProgress) }
        }
        
        let cloudDatabase = CKContainer.default().publicCloudDatabase
        let syncOperation = SyncLocalDatastoreWithRemoteOperation(cloudDatabase: cloudDatabase, persistenceProvider: self)
        
        syncOperation.completionBlock = {
            self.lastSuccessSyncAt = Date()
            
            // Should this be more dependency injected styles?
            OperationQueue.main.addOperation {
                NotificationCenter.default.post(name: .localDatastoreUpdatedWithNewData, object: nil)
            }
            
            resultQueue.addOperation { result?(syncOperation.result) }
        }
        
        syncQueue.addOperation(syncOperation)
    }
    
    // Scheduler Access
    
    func determineSchedulerAccess(
        completionQueue: OperationQueue,
        completion: @escaping (Bool) -> Void)
    {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "SchedulerRole", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: { records, queryError in
            let access = queryError == nil && records != nil
            completionQueue.addOperation { completion(access) }
        })
        
    }
}


