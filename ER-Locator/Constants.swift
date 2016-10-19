//
//  Constants.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-04-05.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation
import CloudKit

enum SnowError: Error {
    case unableToAccessReturnedRecordsOfType(String)
    case unableToLoadCKRecord(CKRecord)
    
    case operationNotComplete
    case operationCancelled
    case operationTimedOut
}

extension Notification.Name {
    static let localDatastoreUpdatedWithNewData = Notification.Name("localDatastoreUpdatedWithNewData")
}
