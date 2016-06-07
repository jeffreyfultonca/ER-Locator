//
//  ScheduleDayProvider.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-06-06.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import Foundation

enum ScheduleDaysFetchResult {
    case Failure(ErrorType)
    case Success([ScheduleDay])
}

enum ScheduleDayFetchResult {
    case Failure(ErrorType)
    case Success(ScheduleDay?)
}

protocol ScheduleDayProvider {
    func fetchScheduleDayForER(er: ER, onDate date: NSDate, handler: (ScheduleDayFetchResult)->() )
}
