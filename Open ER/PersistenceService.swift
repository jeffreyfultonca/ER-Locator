//
//  PersistenceService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class PersistenceService: PersistenceProvider {
    static let sharedInstance = PersistenceService()
    private init() {} // Enforce singleton.
    
    // MARK: - Dependencies
    lazy var defaults = NSUserDefaults.standardUserDefaults()
    lazy var emergencyRoomProvider: EmergencyRoomProvider = EmergencyRoomService.sharedInstance
    
    // MARK: - User Default Keys
    struct UserDefaultKey {
        
        // CloudKitRecordables
        static let EmergencyRooms = "EmergencyRooms"
        static let TodaysScheduleDays = "TodaysScheduleDays"
        
        static let EmergencyRoomsMostRecentlyModifiedAt = "EmergencyRoomsMostRecentlyModifiedAt"
        static let TodaysScheduleDaysMostRecentlyModifiedAt = "TodaysScheduleDaysMostRecentlyModifiedAt"
        
        // Sync
        static let LastSuccessSyncAt = "LastSuccessSyncAt"
    }
    
    // MARK: - Stored Properties
    private let syncQueue = NSOperationQueue()
    
    // MARK: - Storage
    
    var emergencyRooms: Set<ER> {
        get {
            guard let data = defaults.objectForKey(UserDefaultKey.EmergencyRooms) as? NSData else { return Set<ER>() }
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Set<ER> ?? Set<ER>()
        }
        set {
            let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(newValue)
            defaults.setObject(archivedObject, forKey: UserDefaultKey.EmergencyRooms)
        }
    }
    
    var emergencyRoomsMostRecentlyModifiedAt: NSDate? {
        get { return defaults.objectForKey(UserDefaultKey.EmergencyRoomsMostRecentlyModifiedAt) as? NSDate }
        set { defaults.setObject(newValue, forKey: UserDefaultKey.EmergencyRoomsMostRecentlyModifiedAt) }
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
}

