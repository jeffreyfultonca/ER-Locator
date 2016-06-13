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
    var scheduleDayProvider: ScheduleDayProvider = ScheduleDayService.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Properties
    let today = NSDate.now.beginningOfDay
    var er: ER!
//    var scheduleDayCache = [NSDate: ScheduleDay]()
    
    /// Used to save and reload tableView cell on return from ScheduleDayDetailVC.
    var lastSelectedScheduleDay: ScheduleDay?
    
    /// Used to properly configure cells and change request priority during rapid scrolling.
    var saveRequestDates = Set<NSDate>()
    var fetchRequests = Dictionary<NSDate, CloudKitRecordableFetchRequestable>()
    
    // MARK: - Month Sections
    // Used to show faux infinite scrolling.
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
        
        saveLastSelectedScheduleDay()
    }
    
    // MARK: - Helpers
    
    func saveLastSelectedScheduleDay() {
        guard let lastSelectedScheduleDay = lastSelectedScheduleDay else { return }
        
        saveAndUpdateCellForScheduleDay(lastSelectedScheduleDay)
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
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // TODO: Is this doing anything? Is UITableViewAutomaticDimension the default?
        return UITableViewAutomaticDimension
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
    
    func tableView(
        tableView: UITableView,
        willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath)
    {
        guard let cell = cell as? ScheduleDayCell else { return }
        
        let date = dateForIndexPath(indexPath)
        
        if saveRequestDates.contains(date) {
            // Currently saving.
            cell.configureAsSavingWithDate(date)
        
        }
        else if var previousFetchRequest = fetchRequests[date] where previousFetchRequest.finished == false {
            // Raise request priority so onscreen requests process first
            previousFetchRequest.priority = .High
            
        } 
        else {
            // Fetch ScheduleDay and store request in fetchRequests for later re-prioritization.
            fetchRequests[date] = scheduleDayProvider.fetchScheduleDaysForER(
                er,
                onDate: date,
                resultQueue: NSOperationQueue.mainQueue() )
            { result in
                
                // Remove fetchRequest
                self.fetchRequests[date] = nil
                
                // Get cell for indexPath as original cell may have been reused for a different ScheduleDay by now.
                let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? ScheduleDayCell
                
                switch result {
                case .Failure(let error):
                    cell?.configureWithError(error, andDate: date)
                    
                case .Success(let scheduleDays):
                    guard let scheduleDay = scheduleDays.first else {
                        cell?.configureAsClosedWithDate(date)
                        return
                    }
                    
                    cell?.configureWithScheduleDay(scheduleDay)
                }
            }
        }
    }
    
    func tableView(
        tableView: UITableView,
        didEndDisplayingCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath)
    {
        // Lower request priority so onscreen requests process first.
        let date = dateForIndexPath(indexPath)
        
        guard var fetchRequest = fetchRequests[date] else { return }
        fetchRequest.priority = .Normal
    }
    
    func saveAndUpdateCellForScheduleDay(scheduleDay: ScheduleDay) {
        
        let date = scheduleDay.date
        
        // Mark as saving.
        saveRequestDates.insert(date)
        
        // Set cell to 'Saving' if visible
        guard let indexPath = indexPathForDate(date) else { return }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? ScheduleDayCell
        cell?.configureAsSavingWithDate(date)
        
        scheduleDayProvider.saveScheduleDay(
            scheduleDay,
            resultQueue: NSOperationQueue.mainQueue())
        { result in
            
            // Successfully saved
            self.saveRequestDates.remove(date)
            
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? ScheduleDayCell
            cell?.configureAsSavingWithDate(date)
            
            switch result {
            case .Failure(let error):
                print(error)
                cell?.configureWithError(error, andDate: date)
                
            case .Success(let scheduleDays):
                guard let scheduleDay = scheduleDays.first else {
                    return print("Error: Could not access saved ScheduleDay.")
                }
                
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
            
            if let fetchRequest = fetchRequests[date] where fetchRequest.finished == false {
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
                // This is really complicated because there is no synchronous way to get ScheduleDays...
                // Perhaps there should be... or we cache them here... or attach to each cell?
                let date = dateForIndexPath(indexPath)
                
                let group = dispatch_group_create()
                
                dispatch_group_enter(group)
                self.scheduleDayProvider.fetchScheduleDaysForER(
                    self.er,
                    onDate: date,
                    resultQueue: NSOperationQueue() )
                { result in
                    defer { dispatch_group_leave(group) }
                    
                    switch result {
                    case .Failure(let error):
                        print(error)
                        
                    case .Success(let scheduleDays):
                        let scheduleDay = scheduleDays.first ?? self.scheduleDayProvider.createScheduleDayForER(
                            self.er,
                            onDate: date
                        )
                        
                        vc.scheduleDay = scheduleDay
                        self.lastSelectedScheduleDay = scheduleDay
                    }
                }
                
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
            }
        }
    }
}
