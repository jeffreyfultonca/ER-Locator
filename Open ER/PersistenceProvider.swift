//
//  PersistenceProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

enum SyncLocalDatastoreWithRemoteResult {
    case Failure(ErrorType)
    case NoData
    case NewData
    case SyncAlreadyInProgress
}

protocol PersistenceProvider {
    
    // MARK: - Storage
    var emergencyRooms: Set<ER> { get set }
    var emergencyRoomsMostRecentlyModifiedAt: NSDate? { get set }
    
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
