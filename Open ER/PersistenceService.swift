//
//  PersistenceService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

class PersistenceService: PersistenceProvider {
    
    // MARK: - Dependencies
    var defaults = NSUserDefaults.standardUserDefaults()
    
    var emergencyRooms: [ER] {
        get {
            guard let data = defaults.objectForKey(ER.recordType) as? NSData else { return [ER]() }
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [ER] ?? [ER]()
        }
        set {
            let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(newValue)
            defaults.setObject(archivedObject, forKey: ER.recordType)
        }
    }
    
    func updateLocalDatastore(result: (UpdateLocalDatastoreResult -> ())? = nil) {
        
    }
}

