//
//  ER.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit
import CloudKit

class ER: NSObject, CloudKitRecordable, MKAnnotation {
    
    // MARK: - Stored Properties
    
    var record: CKRecord
    
    var name: String
    var phone: String
    var location: CLLocation
    
    // MARK: - Lifecycle
    
    init(record: CKRecord) {
        self.record = record
        self.name = record["name"] as! String
        self.phone = record["phone"] as! String
        self.location = record["location"] as! CLLocation
    }
    
    // MARK: - Computed Properties
    
    // MKAnnotation
    var coordinate: CLLocationCoordinate2D { return self.location.coordinate }
    var title: String? { return self.name }
    
    var hoursOpen: String { return "Loading..." }
    var estimatedWaitTime: String { return "Estimated wait time" }
    
    /// Used for getting directions in Maps App
    var addressDictionary: Dictionary<String, AnyObject> {
        return [
            CNPostalAddressCityKey: self.name,
            CNPostalAddressStateKey: "Manitoba",
            CNPostalAddressCountryKey: "Cananda"
        ]
    }
    
    // CloudKitRecordModelable
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