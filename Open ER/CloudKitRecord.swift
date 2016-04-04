//
//  CloudKitRecord.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-04.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation
import CloudKit

protocol CloudKitRecordProtocol {
    static var recordType: String { get }
}

class CloudKitRecord: NSObject {
    
    // MARK: - Properties
    var recordID: CKRecordID
    
    init(recordID: CKRecordID) {
        self.recordID = recordID
    }
}