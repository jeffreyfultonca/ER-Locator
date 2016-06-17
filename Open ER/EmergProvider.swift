//
//  EmergProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//


import CloudKit

protocol EmergProviding {
    
    /// Synchronous access to all known Emergs. Generally from an in-memory store or perhaps local storage.
    var emergs: [Emerg] { get }
    
    /**
     Provides Emergs with todays ScheduleDay assigned, sorted by proximity to location.
     
     - parameters:
     - location: Used to sort result.
     - limitTo: Maximum number of Emergs to fetch. Defaults to all results.
     - resultQueue: An operation queue for scheduling result closure.
     - result: Closure accepting CloudKitRecordableFetchResult parameter to access results.
     
     - returns: CloudKitRecordableFetchRequest to manage request.
     */
    func fetchEmergsWithTodaysScheduleDayNearestLocation(
        location: CLLocation,
        limitTo: Int?,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<Emerg>)->()
        ) -> CloudKitRecordableFetchRequest<FetchEmergsWithTodaysScheduleDayNearestLocationOperation>
}

class EmergProvider: EmergProviding {
    static let sharedInstance = EmergProvider()
    private init() {} // Enforce singleton.
    
    // MARK: - Dependencies
    var persistenceProvider: PersistenceProvider = PersistenceService.sharedInstance
    var scheduleDayProvider: ScheduleDayProvider = ScheduleDayService.sharedInstance
    
    // MARK: - Stored Properties
    private let workQueue = NSOperationQueue()
    
    var emergs: [Emerg]  {
        return Array(persistenceProvider.emergs)
    }
    
    func fetchEmergsWithTodaysScheduleDayNearestLocation(
        location: CLLocation,
        limitTo limit: Int?,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<Emerg>) -> ())
        -> CloudKitRecordableFetchRequest<FetchEmergsWithTodaysScheduleDayNearestLocationOperation>
    {
        let fetchEmergsWithTodaysScheduleDayNearestLocation = FetchEmergsWithTodaysScheduleDayNearestLocationOperation(
            emergProvider: self,
            scheduleDayProvider: self.scheduleDayProvider,
            location: location,
            limitTo: limit
        )
        
        fetchEmergsWithTodaysScheduleDayNearestLocation.completionBlock = {
            switch fetchEmergsWithTodaysScheduleDayNearestLocation.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let ers):
                resultQueue.addOperationWithBlock { result( .Success(ers)) }
            }
        }
        
        workQueue.addOperation(fetchEmergsWithTodaysScheduleDayNearestLocation)
        
        return CloudKitRecordableFetchRequest(operation: fetchEmergsWithTodaysScheduleDayNearestLocation, queue: workQueue)
    }
}