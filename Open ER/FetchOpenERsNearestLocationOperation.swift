//
//  FetchOpenERsNearestLocationOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-09.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class FetchOpenERsNearestLocationOperation: AsyncOperation {
    
    enum Result {
        case Failure(ErrorType)
        case Success([ER])
    }
    
    // MARK: - Stored Properties
    private var location: CLLocation
    private var limit: Int?
    
    private var queue = NSOperationQueue()
    
    var result = Result.Failure(Error.OperationNotComplete)
    
    // MARK: - Lifecycle
    
    init(location: CLLocation, limitTo limit: Int? = nil) {
        self.location = location
        self.limit = limit
        
        super.init()
    }
    
    override func main() {
        let cloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let showNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: true)
        
        let fetchScheduleDaysOpenNow = FetchCloudKitRecordableOperation<ScheduleDay>(
            cloudDatabase: cloudDatabase,
            predicate: ScheduleDay.OpenNowPredicate
        )
        
        let fetchEmergencyRoomsSortedByProximity = FetchCloudKitRecordableOperation<ER>(
            cloudDatabase: cloudDatabase,
            sortDescriptors: [ER.sortedByProximityToLocation(location)]
        )
        
        let hideNetworkActivityIndicator = NetworkActivityIndicatorOperation(setVisible: false)
        
        let completion = NSBlockOperation {
            switch (fetchScheduleDaysOpenNow.result, fetchEmergencyRoomsSortedByProximity.result) {
            case (.Failure(let scheduleDaysError), .Failure):
                self.completeOperationWithResult( .Failure(scheduleDaysError) )
                
            case (.Failure(let scheduleDaysError), .Success):
                self.completeOperationWithResult( .Failure(scheduleDaysError) )
                
            case (.Success, .Failure(let emergencyRoomsError)):
                self.completeOperationWithResult( .Failure(emergencyRoomsError) )
                
            case (.Success(let scheduleDays), .Success(let ers)):
                let openERs = self.processERs(ers, andScheduleDays: scheduleDays)
                self.completeOperationWithResult( .Success(openERs) )
            }
        }
        
        // Define Dependencies
        fetchScheduleDaysOpenNow.addDependency(showNetworkActivityIndicator)
        fetchEmergencyRoomsSortedByProximity.addDependency(showNetworkActivityIndicator)
        
        hideNetworkActivityIndicator .addDependency(fetchScheduleDaysOpenNow)
        hideNetworkActivityIndicator .addDependency(fetchEmergencyRoomsSortedByProximity)
        
        completion.addDependency(hideNetworkActivityIndicator)
        
        // Start operations
        
        queue.addOperations([
            showNetworkActivityIndicator,
            fetchScheduleDaysOpenNow,
            fetchEmergencyRoomsSortedByProximity,
            hideNetworkActivityIndicator,
            completion
        ], waitUntilFinished: false)
    }
    
    // MARK: - Helpers
    
    private func processERs(ers: [ER], andScheduleDays scheduleDays: [ScheduleDay], limitTo limit: Int? = nil) -> [ER] {
        let erReferences = scheduleDays.map { $0.record["er"] as! CKReference }
        let openERs = ers.filter { erReferences.contains($0.asCKReferenceWithAction(.None)) }
        guard let limit = limit else { return openERs }
        return Array( openERs.prefix(limit) )
    }
    
    private func completeOperationWithResult(result: Result) {
        self.result = result
        completeOperation()
    }
}
