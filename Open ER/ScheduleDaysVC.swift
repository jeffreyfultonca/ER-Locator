//
//  ScheduleDaysVC.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class ScheduleDaysVC: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate
{
    // MARK: - Dependencies
    var erService = ERService.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Properties
    var er: ER!
    var scheduleDayCache = [NSDate: ScheduleDay]()
    
    let today = NSDate.now.beginningOfDay
    
    // MARK: - Month Sections
    static let monthCountConstant = 120 // Enable single value to be used in both count and offset properties.
    let monthCount = monthCountConstant // 50 years in either direction.
    let monthOffset = monthCountConstant / -2 // Set today to middle of possible values
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard er != nil else { fatalError("er dependency not met.") }
        
        setupTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollTableToDate(today, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollTableToDate(today, animated: true)
    }
    
    // MARK: - TableView
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 54
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.showsVerticalScrollIndicator = false // Indicator not helpful with list this long.
    }
    
    /// Set the cell for date param at top of table.
    func scrollTableToDate(date: NSDate, animated: Bool) {
        let section = abs(monthOffset) + (date.monthOrdinal - today.monthOrdinal)
        let row = date.dayOrdinalInMonth - 1 // Subtract one to make zero based.
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: animated)
    }
    
    func dateForIndexPath(indexPath: NSIndexPath) -> NSDate {
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(indexPath.section + monthOffset)
        return firstDayOfOffsetMonth.plusDays(indexPath.row)
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return monthCount
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(section + monthOffset)
        return firstDayOfOffsetMonth.monthAbbreviationString
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get month offset from today by section
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(section + monthOffset)
        let numberOfDaysInMonth = firstDayOfOffsetMonth.numberOfDaysInMonth
        return numberOfDaysInMonth
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("scheduleDayCell", forIndexPath: indexPath) as! ScheduleDayCell
        
        let date = dateForIndexPath(indexPath)
        cell.configureForDate(date)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // Cell at this point will already be in 'loading' state; date configured but without schedule data.
        
        let date = dateForIndexPath(indexPath)
        
        guard let cell = cell as? ScheduleDayCell else {
            return print("Cell not ScheduleDayCell. Nothing to do.")
        }
        
        // Check ScheduleDayCache
        if let scheduleDay = scheduleDayCache[date] {
            cell.configureWithScheduleDay(scheduleDay)
            return
        }
        
        // Query CloudKit, returns on main thread
        erService.fetchScheduleDayForER(er, onDate: date) { result in
            
            // Cell will be nil if not currently visible
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? ScheduleDayCell
            
            switch result {
            case .Failure(let error):
                cell?.configureWithError(error)
                
            case .Success(let scheduleDay):
                guard let scheduleDay = scheduleDay else {
                    cell?.configureAsClosed()
                    return
                }
                
                // Add to cache
                self.scheduleDayCache[date] = scheduleDay
                
                cell?.configureWithScheduleDay(scheduleDay)
            }
        }
    }
}
