//
//  FetchERsNearestLocationOperation.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-06-11.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation
import CoreLocation

class FetchERsNearestLocationOperation: NSOperation, ReprioritizableOperation {
    
    // MARK: - Stored Properties
    private var erProvider: ERProviding
    private var scheduleDayProvider: ScheduleDayProviding
    
    private var location: CLLocation
    private var limit: Int?
    
    var result: FetchResult<ER> = .Failure(Error.OperationNotComplete)
    override func cancel() {
        result = .Failure(Error.OperationCancelled)
        super.cancel()
    }
    
    // MARK: - Lifecycle
    
    init(
        erProvider: ERProviding,
        scheduleDayProvider: ScheduleDayProviding,
        location: CLLocation,
        limitTo limit: Int? = nil,
        priority: RequestPriority = .Normal)
    {
        self.erProvider = erProvider
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
        from existingOperation: FetchERsNearestLocationOperation,
        priority: RequestPriority)
    {
        self.init(
            erProvider: existingOperation.erProvider,
            scheduleDayProvider:  existingOperation.scheduleDayProvider,
            location: existingOperation.location,
            limitTo: existingOperation.limit
        )
    }
    
    override func main() {
        let ers = erProvider.ers.nearestLocation(location)
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
