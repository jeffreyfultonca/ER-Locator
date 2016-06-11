//
//  ScheduleDayService.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

class ScheduleDayService: ScheduleDayProvider {
    static let sharedInstance = ScheduleDayService()
    private init() {}  // Enforce singleton
    
    // MARK: - Dependencies
    var persistenceProvider: PersistenceProvider = PersistenceService.sharedInstance
    
    var todaysScheduleDays: [ScheduleDay] {
        return Array(persistenceProvider.todaysScheduleDays)
    }
    
}
