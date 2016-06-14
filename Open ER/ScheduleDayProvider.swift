//
//  ScheduleDayProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

protocol ScheduleDayProvider {
    var todaysScheduleDays: [ScheduleDay] { get }
    
    func clearCache()
    
    func fetchScheduleDayFromCacheForER(er: ER, onDate: NSDate) -> ScheduleDay?
    
    func fetchScheduleDaysForER(
        er: ER,
        forDates: [NSDate],
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableFetchResult<ScheduleDay>)->()
    ) -> CloudKitRecordableFetchRequestable
    
    func saveScheduleDay(
        scheduleDay: ScheduleDay,
        resultQueue: NSOperationQueue,
        result: (CloudKitRecordableSaveResult<ScheduleDay>)->()
    )
    
    func createScheduleDayForER(er: ER, onDate date: NSDate) -> ScheduleDay
}
