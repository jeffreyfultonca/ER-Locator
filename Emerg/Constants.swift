//
//  Constants.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-04-05.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation
import CloudKit

enum Error: ErrorType {
    case UnableToAccessReturnedRecordsOfType(String)
    case UnableToLoadCKRecord(CKRecord)
    
    case OperationNotComplete
    case OperationCancelled
    case OperationTimedOut
}

struct Notification {
    static let LocalDatastoreUpdatedWithNewData = "LocalDatastoreUpdatedWithNewData"
}