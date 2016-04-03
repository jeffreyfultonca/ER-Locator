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

class ERService {
    static let sharedInstance = ERService()
    
    /// Closures run on main thread
//    func fetchOpenERsNearestLocation(location: CLLocation,
//        failure: (ErrorType) -> (),
//        success: ([ER])->() )
//    {
//        
//    }
    
    /// Handler closure runs on main thread.
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
                
                return ER(name: name, location: location)
            })
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                handler(.Success(ers))
            }
        }
    }
}