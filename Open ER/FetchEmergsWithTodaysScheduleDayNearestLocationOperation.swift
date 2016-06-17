//
//  FetchEmergsWithTodaysScheduleDayNearestLocationOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-11.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation
import CoreLocation

class FetchEmergsWithTodaysScheduleDayNearestLocationOperation: NSOperation, CloudKitRecordableOperationable {
    
    // MARK: - Stored Properties
    private var emergProvider: EmergProviding
    private var scheduleDayProvider: ScheduleDayProvider
    
    private var location: CLLocation
    private var limit: Int?
    
    var result: CloudKitRecordableFetchResult<Emerg> = .Failure(Error.OperationNotComplete)
    override func cancel() {
        result = .Failure(Error.OperationCancelled)
        super.cancel()
    }
    
    // MARK: - Lifecycle
    
    init(
        emergProvider: EmergProviding,
        scheduleDayProvider: ScheduleDayProvider,
        location: CLLocation,
        limitTo limit: Int? = nil,
        priority: CloudKitRecordableFetchRequestPriority = .Normal)
    {
        self.emergProvider = emergProvider
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
        fromExistingOperation existingOperation: FetchEmergsWithTodaysScheduleDayNearestLocationOperation,
        withPriority priority: CloudKitRecordableFetchRequestPriority)
    {
        self.init(
            emergProvider: existingOperation.emergProvider,
            scheduleDayProvider:  existingOperation.scheduleDayProvider,
            location: existingOperation.location,
            limitTo: existingOperation.limit
        )
    }
    
    override func main() {
        let ers = emergProvider.emergs.nearestLocation(location)
        let todaysScheduleDays = self.scheduleDayProvider.todaysScheduleDays
        
        // Get todays ScheduleDay for each Emerg if available.
        ers.forEach { er in
            er.todaysScheduleDay = todaysScheduleDays.filter { scheduleDay in
                scheduleDay.erReference.recordID == er.recordID
            }.first
        }
        
        result = .Success(ers)
    }
}
