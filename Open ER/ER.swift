//
//  ER.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit
import CloudKit

class ER: NSObject, CloudKitModal, MKAnnotation,  NSCoding {
    
    // MARK: - Stored Properties
    
    var record: CKRecord
    
    var name: String
    var phone: String
    var location: CLLocation
    
    var todaysScheduleDay: ScheduleDay?
    
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
    var subtitle: String? { return self.openNow ? "Open Now" : "Possibly Closed" }
    
    var hoursOpen: String {
        guard let
            todaysScheduleDay = todaysScheduleDay,
            firstOpen = todaysScheduleDay.firstOpen,
            firstClose = todaysScheduleDay.firstClose else
        {
            return "Call Ahead"
        }
        
        // Check for 24 Hour availablility
        if firstOpen.isBeginningOfDay && firstClose.isEndOf(firstOpen) {
            return "24 Hours"
        }
        
        // Represent end of day as 11:59pm rather than 12:00am (next day)
        let firstCloseTime = ( firstClose.isEndOf(firstOpen) ) ? "11:59am" : firstClose.time
        
        return "\(firstOpen.time) - \(firstCloseTime)"
    }
    
    var openNow: Bool {
        guard let
            todaysScheduleDay = todaysScheduleDay,
            firstOpen = todaysScheduleDay.firstOpen,
            firstClose = todaysScheduleDay.firstClose else
        {
            return false
        }
        
        let now = NSDate()
        return firstOpen < now && firstClose > now
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
    
    // Hashable
    
    // Required for determining uniqueness in Sets
    override var hashValue: Int {
        return recordID.recordName.hashValue
    }
    
    // Equatable with NSObject subclass
    
    // Required for ==
    override func isEqual(object: AnyObject?) -> Bool {
        guard let rhs = object as? ER else { return false }
        return self.recordID == rhs.recordID
    }
}