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
        get { return defaults.arrayForKey(ER.recordType) as? [ER] ?? [ER]() }
        set { defaults.setObject(newValue, forKey: ER.recordType) }
    }
    
    func updateLocalDatastore(result: (UpdateLocalDatastoreResult -> ())? = nil) {
        
    }
}

