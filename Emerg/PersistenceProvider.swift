//
//  PersistenceProvider.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

// MARK: - PersistenceProviding protocol

protocol PersistenceProviding {
    
    // MARK: - Storage
    var emergs: Set<Emerg> { get set }
    var emergsMostRecentlyModifiedAt: NSDate? { get set }
    
    var todaysScheduleDays: Set<ScheduleDay> { get set }
    
    // MARK: - Sync
    var syncing: Bool { get }
    
    var lastSuccessSyncAt: NSDate? { get set }
    
    /// Update local datastore with any changes from remote datastore and report back status. i.e. Failure, NoData, NewData.
    func syncLocalDatastoreWithRemote(
        resultQueue: NSOperationQueue,
        result: ( SyncLocalDatastoreWithRemoteResult -> () )?
    )
    
    // Scheduler Access
    func determineSchedulerAccess(completionQueue completionQueue: NSOperationQueue, completion: (Bool) -> Void )
}

enum SyncLocalDatastoreWithRemoteResult {
    case Failure(ErrorType)
    case NoData
    case NewData
    case SyncAlreadyInProgress
}

// MARK: - PersistenceProviding singleton implementation

class PersistenceProvider: PersistenceProviding {
    static let sharedInstance = PersistenceProvider()
    private init() {} // Enforce singleton.
    
    // MARK: - Dependencies
    lazy var defaults = NSUserDefaults.standardUserDefaults()
    lazy var emergProvider: EmergProviding = EmergProvider.sharedInstance
    
    // MARK: - User Default Keys
    struct UserDefaultKey {
        
        // CloudKitRecordables
        static let Emergs = "Emergs"
        static let TodaysScheduleDays = "TodaysScheduleDays"
        
        static let EmergsMostRecentlyModifiedAt = "EmergsMostRecentlyModifiedAt"
        static let TodaysScheduleDaysMostRecentlyModifiedAt = "TodaysScheduleDaysMostRecentlyModifiedAt"
        
        // Sync
        static let LastSuccessSyncAt = "LastSuccessSyncAt"
    }
    
    // MARK: - Stored Properties
    private let syncQueue = NSOperationQueue()
    
    // MARK: - Storage
    
    var emergs: Set<Emerg> {
        get {
            guard let data = defaults.objectForKey(UserDefaultKey.Emergs) as? NSData else { return Set<Emerg>() }
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Set<Emerg> ?? Set<Emerg>()
        }
        set {
            let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(newValue)
            defaults.setObject(archivedObject, forKey: UserDefaultKey.Emergs)
        }
    }
    
    var emergsMostRecentlyModifiedAt: NSDate? {
        get { return defaults.objectForKey(UserDefaultKey.EmergsMostRecentlyModifiedAt) as? NSDate }
        set { defaults.setObject(newValue, forKey: UserDefaultKey.EmergsMostRecentlyModifiedAt) }
    }
    
    var todaysScheduleDays: Set<ScheduleDay> {
        get {
            guard let
                data = defaults.objectForKey(UserDefaultKey.TodaysScheduleDays) as? NSData,
                scheduleDays = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Set<ScheduleDay> else
            {
                return Set<ScheduleDay>()
            }
            
            return  scheduleDays.scheduledToday
        }
        set {
            let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(newValue)
            defaults.setObject(archivedObject, forKey: UserDefaultKey.TodaysScheduleDays)
        }
    }
    
    // MARK: - Sync
    
    var syncing: Bool { return
        syncQueue.operationCount > 0
    }
    
    var lastSuccessSyncAt: NSDate? {
        get { return defaults.objectForKey(UserDefaultKey.LastSuccessSyncAt) as? NSDate }
        set { defaults.setObject(newValue, forKey: UserDefaultKey.LastSuccessSyncAt) }
    }
    
    func syncLocalDatastoreWithRemote(
        resultQueue: NSOperationQueue,
        result: ( SyncLocalDatastoreWithRemoteResult -> () )? )
    {
        // Return if sync already in progress
        guard syncing == false else {
            return resultQueue.addOperationWithBlock { result?(.SyncAlreadyInProgress) }
        }
        
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let syncOperation = SyncLocalDatastoreWithRemoteOperation(cloudDatabase: cloudDatabase, persistenceProvider: self)
        
        syncOperation.completionBlock = {
            self.lastSuccessSyncAt = NSDate()
            
            // Should this be more dependency injected styles?
            NSOperationQueue.mainQueue().addOperationWithBlock {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    Notification.LocalDatastoreUpdatedWithNewData,
                    object: nil
                )
            }
            
            resultQueue.addOperationWithBlock { result?(syncOperation.result) }
        }
        
        syncQueue.addOperation(syncOperation)
    }
    
    // Scheduler Access
    
    func determineSchedulerAccess(
        completionQueue completionQueue: NSOperationQueue,
        completion: (Bool) -> Void)
    {
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "SchedulerRole", predicate: predicate)
        
        publicDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { records, queryError in
            let access = queryError == nil && records != nil
            completionQueue.addOperationWithBlock { completion(access) }
        })
        
    }
}


