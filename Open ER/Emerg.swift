//
//  Emerg.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit
import CloudKit

/// Represents a single Emergency Room.
class Emerg: NSObject, CloudKitModal, MKAnnotation,  NSCoding {
    
    // MARK: - Stored Properties
    
    var record: CKRecord
    
    /// ScheduleDay for today's date corresponding to this Emerg. Nil if not available.
    /// Used to quickly display open or possibly closed Emergs.
    var todaysScheduleDay: ScheduleDay?
    
    // MARK: - Lifecycle
    
    required init(record: CKRecord) {
        self.record = record
    }
    
    // MARK: - Computed Properties
    
    var name: String {
        get { return record["name"] as! String }
        set { record["name"] = newValue }
    }
    var phone: String {
        get { return record["phone"] as! String }
        set { record["phone"] = newValue }
    }
    var location: CLLocation {
        get { return record["location"] as! CLLocation }
        set { record["location"] = newValue }
    }
    
    var isOpenNow: Bool {
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
    
    /// String indicating "<open time> - <close time>", "24 Hours", or message to "Call Ahead" if Emerg is possibly closed.
    var hoursOpenMessage: String {
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
        
        // Represent end of day as 11:59pm rather than 12:00am next day
        let firstCloseTime = ( firstClose.isEndOf(firstOpen) ) ? "11:59am" : firstClose.time
        
        return "\(firstOpen.time) - \(firstCloseTime)"
    }
    
    /// Not yet implementable due to lack of available data.
    var estimatedWaitTime: String { return "Estimated wait time" }
    
    /// Used for getting directions in Maps App
    var addressDictionary: Dictionary<String, AnyObject> {
        return [
            CNPostalAddressCityKey: self.name,
            CNPostalAddressStateKey: "Manitoba",
            CNPostalAddressCountryKey: "Cananda"
        ]
    }
    
    // MARK: MKAnnotation
    
    var coordinate: CLLocationCoordinate2D { return self.location.coordinate }
    var title: String? { return self.name }
    var subtitle: String? { return self.isOpenNow ? "Open Now" : "Possibly Closed" }
    
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
    
    // MARK: - Hashable
    
    // Required for determining uniqueness in Sets
    override var hashValue: Int {
        return recordID.recordName.hashValue
    }
    
    // MARK: - Equatable with NSObject subclass
    
    // Required for ==
    override func isEqual(object: AnyObject?) -> Bool {
        guard let rhs = object as? Emerg else { return false }
        return self.recordID == rhs.recordID
    }
    
    // MARK: - Sort Descriptors
    // TODO: Move somewhere else
    static func sortedByProximityToLocation(location: CLLocation) -> CKLocationSortDescriptor {
        return CKLocationSortDescriptor(key: "location", relativeLocation: location)
    }
}