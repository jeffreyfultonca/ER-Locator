//
//  ER.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-04-02.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import MapKit
import CloudKit

class ER: NSObject, CloudKitModel, MKAnnotation,  NSCoding {
    
    // MARK: - Stored Properties
    
    var record: CKRecord
    
    /// ScheduleDay for today's date corresponding to this ER. Nil if not available.
    /// Used to quickly display open or possibly closed ERs.
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
        guard let todaysScheduleDay = todaysScheduleDay,
            let firstOpen = todaysScheduleDay.firstOpen,
            let firstClose = todaysScheduleDay.firstClose else
        {
            return false
        }
        
        let now = Date()
        return firstOpen < now && firstClose > now
    }
    
    /// String indicating "<open time> - <close time>", "24 Hours", or message to "Call Ahead" if ER is possibly closed.
    var hoursOpenMessage: String {
        guard let todaysScheduleDay = todaysScheduleDay,
            let firstOpen = todaysScheduleDay.firstOpen,
            let firstClose = todaysScheduleDay.firstClose else
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
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(record, forKey: PropertyKey.Record)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let record = aDecoder.decodeObject(forKey: PropertyKey.Record) as! CKRecord
        self.init(record: record)
    }
    
    // MARK: - Hashable
    
    // Required for determining uniqueness in Sets
    override var hashValue: Int {
        return recordID.recordName.hashValue
    }
    
    // MARK: - Equatable with NSObject subclass
    
    // Required for ==
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ER else { return false }
        return self.recordID == rhs.recordID
    }
    
    // MARK: - Sort Descriptors
    // TODO: Move somewhere else
    static func sortedByProximityToLocation(_ location: CLLocation) -> CKLocationSortDescriptor {
        return CKLocationSortDescriptor(key: "location", relativeLocation: location)
    }
}
