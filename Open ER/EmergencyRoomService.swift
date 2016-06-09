//
//  EmergencyRoomService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

//import CoreLocation
import CloudKit

class EmergencyRoomService: EmergencyRoomProvider {
    
    // MARK: - Dependencies
    let persistenceProvider: PersistenceProvider
    
    // MARK: - Stored Properties
    private let workQueue = NSOperationQueue()
    
    init(persistenceProvider: PersistenceProvider) {
        self.persistenceProvider = persistenceProvider
    }
    
    /**
     Provides a limited array of currently open ERs sorted by proximity to location.
     
     - Important:
     Supplied result closure will be scheduled internal background queue.
     
     - parameters:
        - location: Used to sort result.
        - limitTo: Maximum number of ERs to fetch. Defaults to all results.
        - resultQueue: An operation queue for scheduling result closure. Defaults to internal background queue.
     */
    func fetchOpenERsNearestLocation(
        location: CLLocation,
        limitTo limit: Int?,
        resultQueue: NSOperationQueue?,
        result: ERsFetchResult -> ())
    {
        // TODO: Replace nil check/default to default param as soon as Swift compilier allows it with protocols.
        let resultQueue = resultQueue ?? NSOperationQueue()
        
        let fetchOpenERsNearestLocation = FetchOpenERsNearestLocationOperation(location: location, limitTo: limit)
        
        fetchOpenERsNearestLocation.completionBlock = {
            switch fetchOpenERsNearestLocation.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let ers):
                resultQueue.addOperationWithBlock { result( .Success(ers)) }
            }
        }
        
        workQueue.addOperation(fetchOpenERsNearestLocation)
    }
}
