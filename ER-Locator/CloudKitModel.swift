//
//  CloudKitModel.swift
//  ER-Locator
//
//  Created by Jeffrey Fulton on 2016-04-04.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import CloudKit

/**
 Defines properties required for a model object to be
 used with CloudKit records (`CKRecords`).
 
 `CKRecords` are not to be used as model objects in 
 our apps according to Apple. We are to define our 
 own models and handle the conversion to/from CloudKit.
 */
protocol CloudKitModel {
    static var recordType: String { get }
    
    var record: CKRecord { get }
    var recordID: CKRecordID { get }
    
    init(record: CKRecord)
}

extension CloudKitModel {
    /**
     String used to determine CloudKit RecordType for this record.
     
     - Returns: String representation of instance's type by default. i.e. `class Person` will have a recordType of "Person". Override by implementing `static var recordType: String` in conforming type.
    */
    static var recordType: String { return String(self) }
    
    /**
     Convenience accessor to associated `CKRecord`'s `CKRecordID`.
    */
    var recordID: CKRecordID { return record.recordID }
}