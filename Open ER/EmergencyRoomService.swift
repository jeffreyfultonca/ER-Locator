//
//  EmergencyRoomService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CoreLocation

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
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let resultQueue = resultQueue ?? NSOperationQueue()
        
        let fetchScheduleDaysOpenNowOperation = FetchScheduleDaysOperation(openAtDate: NSDate())
        let fetchEmergencyRoomsSortByProximityOperation = FetchEmergencyRoomsOperation(sortedByProximityToLocation: location)
        
        let fetchCompletionOperation = NSBlockOperation {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        let processResultsOperation = ProcessResultsOperation(
            scheduleDaysOperation: fetchScheduleDaysOpenNowOperation,
            emergencyRoomsOperation: fetchEmergencyRoomsSortByProximityOperation,
            limitTo: limit
        )
        
        let processCompletionOperation = NSBlockOperation {
            switch processResultsOperation.result {
            case .Failure(let error):
                resultQueue.addOperationWithBlock { result( .Failure(error) ) }
                
            case .Success(let ers):
                resultQueue.addOperationWithBlock { result( .Success(ers)) }
            }
        }
        
        // Define operation dependencies
        fetchCompletionOperation.addDependency(fetchScheduleDaysOpenNowOperation)
        fetchCompletionOperation.addDependency(fetchEmergencyRoomsSortByProximityOperation)
        
        processResultsOperation.addDependency(fetchCompletionOperation)
        processCompletionOperation.addDependency(processResultsOperation)
        
        workQueue.addOperations([
            fetchScheduleDaysOpenNowOperation,
            fetchEmergencyRoomsSortByProximityOperation,
            fetchCompletionOperation,
            processResultsOperation,
            processCompletionOperation
        ], waitUntilFinished: false)
    }
}

import CloudKit
import UIKit

class FetchScheduleDaysOperation: AsyncOperation {
    
    enum Result {
        case Failure(ErrorType)
        case Success([ScheduleDay])
    }
    
    // MARK: - Stored Properties
    var openAtDate: NSDate
    var result = Result.Failure(Error.OperationNotComplete)
    
    init(openAtDate: NSDate) {
        self.openAtDate = openAtDate
        super.init()
    }
    
    override func main() {
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let predicate = NSPredicate(format: "firstOpen <= %@ AND firstClose > %@", openAtDate, openAtDate)
        let query = CKQuery(recordType: ScheduleDay.recordType, predicate: predicate)
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { records, error in
            guard let records = records else {
                let error: ErrorType = error ?? Error.UnableToAccessReturnedRecordsOfType(ScheduleDay.recordType)
                return self.completeOperation( .Failure(error) )
            }
        
            let scheduleDays = records.map { ScheduleDay(record: $0) }
            self.completeOperation( .Success(scheduleDays) )
        }
    }
    
    func completeOperation(result: Result) {
        self.result = result
        completeOperation()
    }
}

class FetchEmergencyRoomsOperation: AsyncOperation {
    
    enum Result {
        case Failure(ErrorType)
        case Success([ER])
    }
    
    // MARK: - Stored Properties
    var location: CLLocation
    var result = Result.Failure(Error.OperationNotComplete)
    
    init(sortedByProximityToLocation location: CLLocation) {
        self.location = location
        super.init()
    }
    
    override func main() {
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: ER.recordType, predicate: predicate)
        query.sortDescriptors = [CKLocationSortDescriptor(key: "location", relativeLocation: location)]
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { records, error in
            guard let records = records else {
                let error: ErrorType = error ?? Error.UnableToAccessReturnedRecordsOfType(ScheduleDay.recordType)
                return self.completeOperation( .Failure(error) )
            }
            
            let ers = records.map { ER(record: $0) }
            self.completeOperation( .Success(ers) )
        }
    }
    
    func completeOperation(result: Result) {
        self.result = result
        completeOperation()
    }
}

class ProcessResultsOperation: NSOperation {
  
    enum Result {
        case Failure(ErrorType)
        case Success([ER])
    }
    
    // MARK: - Stored Properties
    var scheduleDaysOperation: FetchScheduleDaysOperation
    var emergencyRoomsOperation: FetchEmergencyRoomsOperation
    var limit: Int?
    var result = Result.Failure(Error.OperationNotComplete)
    
    init(
        scheduleDaysOperation: FetchScheduleDaysOperation,
        emergencyRoomsOperation: FetchEmergencyRoomsOperation,
        limitTo limit: Int?)
    {
        self.scheduleDaysOperation = scheduleDaysOperation
        self.emergencyRoomsOperation = emergencyRoomsOperation
        self.limit = limit
        super.init()
    }
    
    override func main() {
        switch (scheduleDaysOperation.result, emergencyRoomsOperation.result) {
        case (.Failure(let scheduleDaysError), .Failure):
            result = .Failure(scheduleDaysError)
            
        case (.Failure(let scheduleDaysError), .Success):
            result = .Failure(scheduleDaysError)
            
        case (.Success, .Failure(let emergencyRoomsError)):
            result = .Failure(emergencyRoomsError)
            
        case (.Success(let scheduleDays), .Success(let ers)):
            let openERs = processERs(ers, andScheduleDays: scheduleDays, limitTo: limit)
            result = .Success(openERs)
        }
    }
    
    func processERs(ers: [ER], andScheduleDays scheduleDays: [ScheduleDay], limitTo limit: Int?) -> [ER] {
        let erReferences = scheduleDays.map { $0.record["er"] as! CKReference }
        let openERs = ers.filter { erReferences.contains($0.asCKReferenceWithAction(.None)) }
        guard let limit = limit else { return openERs }
        return Array( openERs.prefix(limit) )
    }
}




