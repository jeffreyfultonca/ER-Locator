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
    
    // MARK: - CloudKitProtocol
    static var recordType = "ER"
    
    // MARK: - Properties
    var name: String
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
    
    init(
        recordID: CKRecordID,
        name: String,
        location: CLLocation)
    {
        self.name = name
        self.location = location
        
        super.init(recordID: recordID)
    }
}