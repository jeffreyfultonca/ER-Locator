//
//  ERService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CoreLocation
import CloudKit

enum ERsFetchResult {
    case Success([ER])
    case Failure(ErrorType)
}
typealias ERsFetchHandler = (ERsFetchResult) -> Void

enum ScheduleDaysFetchResult {
    case Success([ScheduleDay])
    case Failure(ErrorType)
}
typealias ScheduleDaysFetchHandler = (ScheduleDaysFetchResult) -> Void


class ERService {
    static let sharedInstance = ERService()
    
    // MARK: - ERs
    
    /// Handler runs on main thread.
    func fetchAllERs(handler: ERsFetchHandler) {
        let container = CKContainer.defaultContainer()
        let publicDatabase = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "ER", predicate: NSPredicate(value: true) )
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            guard let records = records else {
                return NSOperationQueue.mainQueue().addOperationWithBlock {
                    handler(.Failure(error!))
                }
            }
            
            let ers = records.map({ record -> ER in
                let name = record["name"] as! String
                let location = record["location"] as! CLLocation
                let recordID = record.recordID
                
                return ER(name: name, location: location, recordID: recordID)
            })
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                handler(.Success(ers))
            }
        }   
    }
    
    /// Handler runs on main thread.
    func fetchOpenERsNearestLocation(location: CLLocation, handler: ERsFetchHandler) {
        let container = CKContainer.defaultContainer()
        let publicDatabase = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "ER", predicate: NSPredicate(value: true) )
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            guard let records = records else {
                return NSOperationQueue.mainQueue().addOperationWithBlock {
                    handler(.Failure(error!))
                }
            }
            
            let ers = records.map({ record -> ER in
                let name = record["name"] as! String
                let location = record["location"] as! CLLocation
                let recordID = record.recordID
                
                return ER(name: name, location: location, recordID: recordID)
            })
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                handler(.Success(ers))
            }
        }
    }
    
    // MARK: - ScheduleDays
    
    func fetchScheduleDaysForER(er: ER, handler: ScheduleDaysFetchHandler) {
        let container = CKContainer.defaultContainer()
        let publicDatabase = container.publicCloudDatabase
        
        let predicate = NSPredicate(format: "er == %@", er.recordID)
        let query = CKQuery(recordType: "ScheduleDay", predicate: predicate )
        
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error) in
            guard let records = records else {
                return NSOperationQueue.mainQueue().addOperationWithBlock {
                    handler(.Failure(error!))
                }
            }
            
            let scheduleDays = records.map({ record -> ScheduleDay in
                let date = record["date"] as! NSDate
                
                return ScheduleDay(date: date)
            })
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                handler(.Success(scheduleDays))
            }
        }
    }
    
}