//
//  FetchERsWithTodaysScheduleDayNearestLocationOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-11.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation
import CoreLocation

class FetchERsWithTodaysScheduleDayNearestLocationOperation: NSOperation, CloudKitRecordableOperationable {
    
    // MARK: - Stored Properties
    private var emergencyRoomProvider: EmergencyRoomProvider
    private var scheduleDayProvider: ScheduleDayProvider
    
    private var location: CLLocation
    private var limit: Int?
    
    var result: CloudKitRecordableFetchResult<ER> = .Failure(Error.OperationNotComplete)
    
    // MARK: - Lifecycle
    
    init(
        emergencyRoomProvider: EmergencyRoomProvider,
        scheduleDayProvider: ScheduleDayProvider,
        location: CLLocation,
        limitTo limit: Int? = nil,
        priority: CloudKitRecordableFetchRequestPriority = .Normal)
    {
        self.emergencyRoomProvider = emergencyRoomProvider
        self.scheduleDayProvider = scheduleDayProvider
        
        self.location = location
        self.limit = limit
        
        super.init()
        
        // TODO: This is duplicated between all the CloudKitRecordableOperationable classes. Move somewhere common?
        switch priority {
        case .Normal:
            qualityOfService = .Utility
            queuePriority = .Normal
        
        case .High:
            qualityOfService = .UserInitiated
            queuePriority = .High
        }
    }
    
    required convenience init(
        fromExistingOperation existingOperation: FetchERsWithTodaysScheduleDayNearestLocationOperation,
        withPriority priority: CloudKitRecordableFetchRequestPriority)
    {
        self.init(
            emergencyRoomProvider: existingOperation.emergencyRoomProvider,
            scheduleDayProvider:  existingOperation.scheduleDayProvider,
            location: existingOperation.location,
            limitTo: existingOperation.limit
        )
    }
    
    override func main() {
        let ers = emergencyRoomProvider.emergencyRooms.nearestLocation(location)
        let todaysScheduleDays = self.scheduleDayProvider.todaysScheduleDays
        
        // Get todays ScheduleDay for each ER if available.
        ers.forEach { er in
            er.todaysScheduleDay = todaysScheduleDays.filter { scheduleDay in
                scheduleDay.erReference.recordID == er.recordID
            }.first
        }
        
        result = .Success(ers)
    }
}
