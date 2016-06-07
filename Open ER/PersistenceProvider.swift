//
//  PersistenceProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

enum UpdateLocalDatastoreResult {
    case Failure(ErrorType)
    case NoData
    case NewData
}

protocol PersistenceProvider {
    var emergencyRooms: [ER] { get set }
    
    /// Update local datastore with any changes from remote datastore and report back status. i.e. Failure, NoData, NewData.
    func updateLocalDatastore(result: (UpdateLocalDatastoreResult -> () )?)
}

