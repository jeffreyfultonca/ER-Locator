//
//  ER.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit
import CloudKit

class ER: NSObject, MKAnnotation {
    
    // MARK: - Properties
    var name: String
    var location: CLLocation
    
    // MARK: CloudKit
    var recordID: CKRecordID
    
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
        name: String,
        location: CLLocation,
        recordID: CKRecordID)
    {
        self.name = name
        self.location = location
        self.recordID = recordID
    }
}