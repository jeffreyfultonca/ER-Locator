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
    
    /// Used to reload tableView cell if set.
    var lastSelectedDate: NSDate?
    
    /// Used to limit network requests
    var datesSaving = Set<NSDate>()
    var datesRequested = Set<NSDate>()
    var datesFetched = Set<NSDate>()
    
    // MARK: - Month Sections
    static let monthCountConstant = 120 // Enable single value to be used in both count and offset properties.
    let monthCount = monthCountConstant // 50 years in either direction.
    let monthOffset = monthCountConstant / -2 // Set today to middle of possible values
    
    var shouldScrollToTodayAppear = true
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard er != nil else { fatalError("er dependency not met.") }
        
        navigationItem.title = "\(er.name) Schedule"
        
        setupTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
      
        if shouldScrollToTodayAppear {
            scrollTableToDate(today, animated: false)
        }
        
        // Reload cell for last selected date.
        if let
            lastSelectedDate = lastSelectedDate,
            indexPath = indexPathForDate(lastSelectedDate)
        {
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        }
        
        // Save ScheduleDay for last selected date.
        if let
            lastSelectedDate = lastSelectedDate,
            scheduleDay = scheduleDayCache[lastSelectedDate]
        {
            saveAndUpdateCellForScheduleDay(scheduleDay)
        }
        
        lastSelectedDate = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldScrollToTodayAppear {
            shouldScrollToTodayAppear = false
            scrollTableToDate(today, animated: true)
        }
    }
    
    // MARK: - TableView
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 54.5
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.showsVerticalScrollIndicator = false // Indicator not helpful with list this long.
        tableView.scrollsToTop = false // Top in this case is years previous.
    }
    
    /// Set the cell for date param at top of table.
    func scrollTableToDate(date: NSDate, animated: Bool) {
        if let indexPath = indexPathForDate(date){
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: animated)
        }
    }
    
    func dateForIndexPath(indexPath: NSIndexPath) -> NSDate {
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(indexPath.section + monthOffset)
        return firstDayOfOffsetMonth.plusDays(indexPath.row)
    }
    
    func indexPathForDate(date: NSDate) -> NSIndexPath? {
        let section = abs(monthOffset) + (date.monthOrdinal - today.monthOrdinal)
        let row = date.dayOrdinalInMonth - 1 // Subtract one to make zero based.
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        return indexPath
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return monthCount
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(section + monthOffset)
        return firstDayOfOffsetMonth.monthFullName
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
        
        if datesSaving.contains(date) {
            print("Saving in progress")
            cell.configureAsSavingWithDate(date)
        }
        // Check ScheduleDayCache
        else if let scheduleDay = scheduleDayCache[date] {
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
                print(error)
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
    
    func saveAndUpdateCellForScheduleDay(scheduleDay: ScheduleDay) {
        
        let date = scheduleDay.date
        
        // Mark as saving.
        datesSaving.insert(date)
        
        // Set cell to 'Saving' if visible
        guard let indexPath = indexPathForDate(date) else {
            print("Could not access indexPathForDate: \(date)")
            return
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? ScheduleDayCell
        cell?.configureAsSavingWithDate(date)
        
        erService.saveScheduleDay(scheduleDay) { result in
            
            // Successfully saved
            self.datesSaving.remove(date)
            
            switch result {
            case .Failure(let error):
                print(error)
                cell?.configureWithError(error, andDate: date)
                
            case .Success(let scheduleDay):
                print("Successfully saved: \(scheduleDay)")
                cell?.configureWithScheduleDay(scheduleDay)
            }
        }
    }
    
    // MARK: - Segues
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showScheduleDayDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow else {
                print("Could not access selected indexPath.")
                return false
            }
            
            let date = dateForIndexPath(indexPath)
            
            guard datesFetched.contains(date) else {
                print("Not finished fetching ScheduleDay for date... try again when complete.")
                return false
            }
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showScheduleDayDetail" {
            if let
                vc = segue.destinationViewController as? ScheduleDayDetailVC,
                indexPath = tableView.indexPathForSelectedRow
            {
                let date = dateForIndexPath(indexPath)
                self.lastSelectedDate = date
                
                // Provide cached ScheduleDay if exists.
                if let scheduleDay = scheduleDayCache[date] {
                    vc.scheduleDay = scheduleDay
                    
                // Create new ScheduleDay if needed.
                } else {
                    let scheduleDay = erService.createScheduleDayForER(er, onDate: date)
                    scheduleDayCache[date] = scheduleDay
                    vc.scheduleDay = scheduleDay
                }
            }
        }
    }
}
