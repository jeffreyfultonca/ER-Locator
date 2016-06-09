//
//  FetchOpenERsNearestLocationOperation.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-09.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

class FetchOpenERsNearestLocationOperation: AsyncOperation {
    
    // MARK: - Stored Properties
    private var location: CLLocation
    private var limit: Int?
    
    private var queue = NSOperationQueue()
    
    var result: FetchCloudKitRecordableResult<ER> = .Failure(Error.OperationNotComplete)
    
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
    
    private func processERs(
        ers: [ER],
        andScheduleDays scheduleDays: [ScheduleDay],
        limitTo limit: Int? = nil) -> [ER]
    {
        // Filter ers which have ScheduleDay and assign that scheduleDay to the er.
        let openERs = ers.filter { er in
            // Get ScheduleDay with matching reference.
            guard let scheduleDay = scheduleDays.filter({ $0.erReference.recordID == er.recordID }).first else
            {
                return false
            }
            er.scheduleDay = scheduleDay
            return true
        }
        
        guard let limit = limit else { return openERs }
        
        return Array( openERs.prefix(limit) )
    }
    
    private func completeOperationWithResult(result: FetchCloudKitRecordableResult<ER>) {
        self.result = result
        completeOperation()
    }
}

class FetchOpenERsNearestLocationRequest {
    private var operation: FetchOpenERsNearestLocationOperation
    private var queue: NSOperationQueue
    
    var finished: Bool {
        return operation.finished
    }
    
    var priority: NSOperationQueuePriority = .Normal {
        didSet(oldPriority) {
            guard operation.executing == false else { return }
            
            let newOperation = FetchOpenERsNearestLocationOperation(
                location: operation.location,
                limitTo: operation.limit
            )
            operation.cancel()
            operation = newOperation
            queue.addOperation(operation)
        }
    }
    
    init(operation: FetchOpenERsNearestLocationOperation, queue: NSOperationQueue) {
        self.operation = operation
        self.queue = queue
    }
    
    func cancel() {
        operation.cancel()
    }
    
}

