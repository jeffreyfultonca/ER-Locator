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
    static let sharedInstance = EmergencyRoomService()
    private init() {} // Enforce singleton.
    
    // MARK: - Dependencies
    var persistenceProvider: PersistenceProvider = PersistenceService.sharedInstance
    var scheduleDayProvider: ScheduleDayProvider = ScheduleDayService.sharedInstance
    
    // MARK: - Stored Properties
    private let workQueue = NSOperationQueue()
    
    var emergencyRooms: [ER]  {
        return Array(persistenceProvider.emergencyRooms)
    }
    
    /**
     Provides a limited number of Emergency Rooms with todays ScheduleDay, if available, sorted by proximity to location.
     
     - parameters:
         - location: Used to sort result.
         - limitTo: Maximum number of ERs to fetch. Defaults to all results.
         - resultQueue: An operation queue for scheduling result closure.
         - result: Closure accepting CloudKitRecordableFetchResult parameter to access results.
     
     - returns: CloudKitRecordableFetchRequest to manage request.
     */
    func fetchERsWithTodaysScheduleDayNearestLocation(
        location: CLLocation,
        limitTo limit: Int?,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<ER>) -> ())
        -> CloudKitRecordableFetchRequest<FetchERsWithTodaysScheduleDayNearestLocationOperation>
    {
        let fetchERsWithTodaysScheduleDayNearestLocation = FetchERsWithTodaysScheduleDayNearestLocationOperation(
            emergencyRoomProvider: self,
            scheduleDayProvider: self.scheduleDayProvider,
            location: location,
            limitTo: limit
        )
        
        fetchERsWithTodaysScheduleDayNearestLocation.completionBlock = {
            switch fetchERsWithTodaysScheduleDayNearestLocation.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let ers):
                resultQueue.addOperationWithBlock { result( .Success(ers)) }
            }
        }
        
        workQueue.addOperation(fetchERsWithTodaysScheduleDayNearestLocation)
        
        return CloudKitRecordableFetchRequest(operation: fetchERsWithTodaysScheduleDayNearestLocation, queue: workQueue)
    }
}
