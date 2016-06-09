//
//  EmergencyRoomProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CoreLocation

enum ERsFetchResult {
    case Failure(ErrorType)
    case Success([ER])
}

protocol EmergencyRoomProvider {
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
        limitTo: Int?,
        resultQueue: NSOperationQueue?,
        result: (ERsFetchResult)->()
    ) -> FetchOpenERsNearestLocationRequest
}