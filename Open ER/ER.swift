//
//  ER.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit
import CloudKit

class ER: NSObject, CloudKitRecordable, MKAnnotation, NSCoding {
    
    // MARK: - Stored Properties
    
    var record: CKRecord
    
    var name: String
    var phone: String
    var location: CLLocation
    
    var scheduleDay: ScheduleDay?
    
    // MARK: - Lifecycle
    
    required init(record: CKRecord) {
        self.record = record
        self.name = record["name"] as! String
        self.phone = record["phone"] as! String
        self.location = record["location"] as! CLLocation
    }
    
    // MARK: - Computed Properties
    
    // MKAnnotation
    var coordinate: CLLocationCoordinate2D { return self.location.coordinate }
    var title: String? { return self.name }
    
    var hoursOpen: String {
        guard let
            scheduleDay = scheduleDay,
            firstOpen = scheduleDay.firstOpen,
            firstClose = scheduleDay.firstClose else
        {
            return "Call Ahead"
        }
        
        return "\(firstOpen.time) - \(firstClose.time)"
    }
    
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
    
    // Sort Descriptors
    
    static func sortedByProximityToLocation(location: CLLocation) -> CKLocationSortDescriptor {
        return CKLocationSortDescriptor(key: "location", relativeLocation: location)
    }
    
    // MARK: - NSCoding
    
    struct PropertyKey {
        static let Record = "RecordKey"
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(record, forKey: PropertyKey.Record)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let record = aDecoder.decodeObjectForKey(PropertyKey.Record) as! CKRecord
        self.init(record: record)
    }
}