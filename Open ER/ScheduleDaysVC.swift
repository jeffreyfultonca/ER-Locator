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
    let today = NSDate.now.beginningOfDay
    var er: ER!
    var scheduleDayCache = [NSDate: ScheduleDay]()
    
    /// Used to limit network requests
    var datesRequested = Set<NSDate>()
    var datesFetched = Set<NSDate>()
    
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
        
        tableView.estimatedRowHeight = 54.5
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
        cell.configureAsLoadingWithDate(date)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? ScheduleDayCell else {
            print("Not ScheduleDayCell; nothing to do.")
            return
        }
        
        let date = dateForIndexPath(indexPath)
        
        // Check ScheduleDayCache
        if let scheduleDay = scheduleDayCache[date] {
            print("Loaded from cache: \(date)")
            cell.configureWithScheduleDay(scheduleDay)
        }
        // Loading if request in progress
        else if datesRequested.contains(date) {
            print("Request in progress: \(date)")
            cell.configureAsLoadingWithDate(date)
        }
        // Closed if already fetched and not cached or requested
        else if datesFetched.contains(date) {
            print("Already fetched: \(date)")
            cell.configureAsClosedWithDate(date)
        }
            // Fetch from CloudKit
        else {
            print("Fetching from CloudKit: \(date)")
            fetchAndUpdateCellAtIndexPath(indexPath)
        }
    }
    
    func fetchAndUpdateCellAtIndexPath(indexPath: NSIndexPath) {
        let date = dateForIndexPath(indexPath)
        
        // Prevent duplicate network requests
        self.datesRequested.insert(date)
        
        // Fetch from CloudKit
        erService.fetchScheduleDayForER(er, onDate: date) { result in
            
            // Remove from requested list
            self.datesRequested.remove(date)
            
            // Cell will be nil if not currently visible
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? ScheduleDayCell
            
            switch result {
            case .Failure(let error):
                cell?.configureWithError(error, andDate: date)
                
            case .Success(let scheduleDay):
                // Successfully fetched
                self.datesFetched.insert(date)
                
                guard let scheduleDay = scheduleDay else {
                    // Nil result means closed
                    cell?.configureAsClosedWithDate(date)
                    return
                }
                
                // Add to cache
                self.scheduleDayCache[date] = scheduleDay
                
                cell?.configureWithScheduleDay(scheduleDay)
            }
        }
    }
}
