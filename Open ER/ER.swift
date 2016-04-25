//
//  ER.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit
import CloudKit

class ER: CloudKitRecord, CloudKitRecordProtocol, MKAnnotation {
    
    // MARK: - Properties
    
    var name: String
    var phone: String
    var location: CLLocation
    
    // MARK: MKAnnotation
    
    var coordinate: CLLocationCoordinate2D { return self.location.coordinate }
    var title: String? { return self.name }
    
    // MARK: Computed
    
    var hoursOpen: String {
        return "12AM - 12PM"
    }
    
    var estimatedWaitTime: String {
        return "Estimated wait time"
    }
    
    // MARK: - Lifecycle
    
    override init(record: CKRecord) {
        self.name = record["name"] as! String
        self.phone = record["phone"] as! String
        self.location = record["location"] as! CLLocation
        
        super.init(record: record)
    }
    
    // MARK: - CloudKitProtocol
    static var recordType = "ER"
    
    var asCKRecord: CKRecord {
        record["name"] = name
        record["location"] = location
        
        return record
    }
    
    func asCKReferenceWithAction(action: CKReferenceAction) -> CKReference {
        let record = self.asCKRecord
        return CKReference(record: record, action: action)
    }
}