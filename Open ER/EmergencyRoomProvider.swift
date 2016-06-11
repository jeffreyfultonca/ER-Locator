//
//  EmergencyRoomProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CoreLocation

protocol EmergencyRoomProvider {
    
    var emergencyRooms: [ER] { get }
    
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
        limitTo: Int?,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<ER>)->()
    ) -> CloudKitRecordableFetchRequest<FetchERsWithTodaysScheduleDayNearestLocationOperation>
}