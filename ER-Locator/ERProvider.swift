//
//  ERProvider.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//


import CloudKit

// MARK: - ERProviding Protocol

protocol ERProviding {
    
    /// Synchronous access to all known ERs. Generally from an in-memory store or perhaps local storage.
    var ers: [ER] { get }
    
    /**
     Provides ERs with todays ScheduleDay assigned, sorted by proximity to location.
     
     - parameters:
     - location: Used to sort result.
     - limitTo: Maximum number of ERs to fetch. Defaults to all results.
     - resultQueue: An operation queue for scheduling result closure.
     - result: Closure accepting CloudKitRecordableFetchResult parameter to access results.
     
     - returns: CloudKitRecordableFetchRequest to manage request.
     */
    func fetchERsWithTodaysScheduleDayNearestLocation(
        _ location: CLLocation,
        limitTo: Int?,
        resultQueue: OperationQueue,
        result: (FetchResult<ER>)->()
        ) -> FetchRequest<FetchERsNearestLocationOperation>
}

// MARK: - Default Singleton Implementation

class ERProvider: ERProviding {
    static let sharedInstance = ERProvider()
    private init() {} // Enforce singleton.
    
    // MARK: - Dependencies
    
    var persistenceProvider: PersistenceProviding = PersistenceProvider.sharedInstance
    var scheduleDayProvider: ScheduleDayProviding = ScheduleDayProvider.sharedInstance
    
    // MARK: - Stored Properties
    
    private let workQueue = OperationQueue()
    
    // MARK: - Computed Properties
    
    var ers: [ER]  {
        return Array(persistenceProvider.ers)
    }
    
    // MARK: - Required Functions
    
    func fetchERsWithTodaysScheduleDayNearestLocation(
        _ location: CLLocation,
        limitTo limit: Int?,
        resultQueue: OperationQueue,
        result: @escaping (FetchResult<ER>) -> ())
        -> FetchRequest<FetchERsNearestLocationOperation>
    {
        let fetchERsNearestLocation = FetchERsNearestLocationOperation(
            erProvider: self,
            scheduleDayProvider: self.scheduleDayProvider,
            location: location,
            limitTo: limit
        )
        
        fetchERsNearestLocation.completionBlock = {
            switch fetchERsNearestLocation.result {
            case .failure(let error):
                resultQueue.addOperation { result( .failure(error) ) }
                
            case .success(let ers):
                resultQueue.addOperation { result( .success(ers)) }
            }
        }
        
        workQueue.addOperation(fetchERsNearestLocation)
        
        return FetchRequest(operation: fetchERsNearestLocation, queue: workQueue)
    }
}
