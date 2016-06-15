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
    
    /// Used to save and reload tableView cell on return from ScheduleDayDetailVC.
    var lastSelectedScheduleDay: ScheduleDay?
    
    /// Used to properly configure cells and change request priority during rapid scrolling.
    var saveRequestDates = Set<NSDate>()
    var fetchRequests = Dictionary<Int, CloudKitRecordableFetchRequestable>()
    
    // MARK: - Month Sections
    // Used to show faux infinite scrolling.
    static let monthCountConstant = 120 // Enable single value to be used in both count and offset properties.
    let monthCount = monthCountConstant // 50 years in either direction.
    let monthOffset = monthCountConstant / -2 // Set today to middle of possible values
    
    var shouldScrollToTodayOnViewWillAppear = true
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard er != nil else { fatalError("er dependency not met.") }
        navigationItem.title = "\(er.name) Schedule"
        
        setupTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
      
        if shouldScrollToTodayOnViewWillAppear {
            shouldScrollToTodayOnViewWillAppear = false
            scrollTableToDate(today, position: .Top, animated: false)
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
    func scrollTableToDate(date: NSDate, position: UITableViewScrollPosition, animated: Bool) {
        if let indexPath = indexPathForDate(date){
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: animated)
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
    
    private var inMemoryScheduleDayCache = InMemoryScheduleDayCache()
    
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
            return
        
        } else if var previousFetchRequest = fetchRequests[indexPath.section]
            where previousFetchRequest.finished == false {
            
            // Raise request priority so onscreen requests process first
            // Has no effect if request has already started executing.
            previousFetchRequest.priority = .High
            
        } else if let scheduleDay = scheduleDayProvider.fetchScheduleDayFromCacheForER(er, onDate: date) {
            // Load from cache
            cell.configureWithScheduleDay(scheduleDay)
            
        } else {
            // Get range of dates in month for this cell
            let datesInMonth = date.datesInMonth
            
            // Get FetchRequest for range and store to prevent future attempts for the same section
            fetchRequests[indexPath.section] = scheduleDayProvider.fetchScheduleDaysForER(
                er,
                forDates: datesInMonth,
                resultQueue: NSOperationQueue.mainQueue())
            { result in
                
                // Remove requests for dates
                self.fetchRequests[indexPath.section] = nil
                
                let indexPathsToRefresh = datesInMonth.map { self.indexPathForDate($0)! }
                
                indexPathsToRefresh.forEach { indexPathToRefresh in
                    let cellToRefresh = tableView.cellForRowAtIndexPath(indexPathToRefresh) as? ScheduleDayCell
                    let dateToRefresh = self.dateForIndexPath(indexPathToRefresh)
                    
                    switch result {
                    case .Failure(let error as Error):
                        switch error {
                        case .OperationCancelled:
                            // Do nothing? Or set to loading?
                            break

                        default:
                            cellToRefresh?.configureWithError(error, andDate: dateToRefresh)
                        }
                    case .Failure(let error):
                        cellToRefresh?.configureWithError(error, andDate: dateToRefresh)
                        
                    case .Success(let scheduleDays):
                        guard let scheduleDay = scheduleDays.filter({ $0.date == dateToRefresh }).first else { break }
                        cellToRefresh?.configureWithScheduleDay(scheduleDay)
                    }
                }
            }
        }
    }
    
    func tableView(
        tableView: UITableView,
        didEndDisplayingCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath)
    {
        // Prevent re-prioritization of still visible cells by confirming different section number.
        let visibleIndexPaths = tableView.indexPathsForVisibleRows!
        let visibleSections = visibleIndexPaths.map { $0.section }
        guard visibleSections.contains(indexPath.section) == false else { return }
        
        // Re-prioritized if possible
        guard var fetchRequest = fetchRequests[indexPath.section] else { return }
        fetchRequest.priority = .Normal
    }
    
    // MARK: Saving
    
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
    
    // MARK: - Actions
    
    @IBAction func todayTapped(sender: AnyObject) {
        scrollTableToDate(today, position: .Top, animated: true)
    }
    
    // MARK: - Segues
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showScheduleDayDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow else {
                print("Could not access selected indexPath.")
                return false
            }
            
            let date = dateForIndexPath(indexPath)
            return scheduleDayProvider.fetchScheduleDayFromCacheForER(er, onDate: date) != nil
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showScheduleDayDetail" {
            let vc = segue.destinationViewController as! ScheduleDayDetailVC
            let indexPath = tableView.indexPathForSelectedRow!
            let date = dateForIndexPath(indexPath)
            let scheduleDay = scheduleDayProvider.fetchScheduleDayFromCacheForER(er, onDate: date)!
            
            vc.scheduleDay = scheduleDay
            self.lastSelectedScheduleDay = scheduleDay
        }
    }
}
