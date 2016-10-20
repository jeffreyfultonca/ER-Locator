//
//  ScheduleDaysVC.swift
//  ER-Locator
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
    var scheduleDayProvider: ScheduleDayProviding = ScheduleDayProvider.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Properties
    let today = Date.now.beginningOfDay
    var er: ER!
    
    /// Used to save and reload tableView cell on return from ScheduleDayDetailVC.
    var lastSelectedScheduleDay: ScheduleDay?
    
    /// Used to properly configure cells and change request priority during rapid scrolling.
    var saveRequestDates = Set<Date>()
    var fetchRequests = Dictionary<Int, ReprioritizableRequest>()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        if shouldScrollToTodayOnViewWillAppear {
            shouldScrollToTodayOnViewWillAppear = false
            scrollTable(to: today, position: .top, animated: false)
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // TODO: Is this doing anything? Is UITableViewAutomaticDimension the default?
        return UITableViewAutomaticDimension
    }
    
    /// Set the cell for date param at top of table.
    func scrollTable(to date: Date, position: UITableViewScrollPosition, animated: Bool) {
        if let indexPath = indexPath(for: date){
            tableView.scrollToRow(at: indexPath, at: position, animated: animated)
        }
    }
    
    func date(for indexPath: IndexPath) -> Date {
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(indexPath.section + monthOffset)
        return firstDayOfOffsetMonth.plusDays(indexPath.row)
    }
    
    func indexPath(for date: Date) -> IndexPath? {
        let section = abs(monthOffset) + (date.monthOrdinal - today.monthOrdinal)
        let row = date.dayOrdinalInMonth - 1 // Subtract one to make zero based.
        let indexPath = IndexPath(row: row, section: section)
        return indexPath
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return monthCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(section + monthOffset)
        return firstDayOfOffsetMonth.monthFullName
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get month offset from today by section
        let firstDayOfOffsetMonth = today.firstDayOfMonthWithOffset(section + monthOffset)
        let numberOfDaysInMonth = firstDayOfOffsetMonth.numberOfDaysInMonth
        return numberOfDaysInMonth
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleDayCell", for: indexPath) as! ScheduleDayCell
        
        let date = self.date(for: indexPath)
        cell.configure(for: date, as: .Loading)
        
        return cell
    }
    
    private var inMemoryScheduleDayCache = InMemoryScheduleDayCache()
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath)
    {
        guard let cell = cell as? ScheduleDayCell else { return }
        
        let date = self.date(for: indexPath)
        
        if saveRequestDates.contains(date) {
            // Currently saving.
            cell.configure(for: date, as: .Saving)
            return
        
        } else if var previousFetchRequest = fetchRequests[indexPath.section],
            previousFetchRequest.finished == false
        {    
            // Raise request priority so onscreen requests process first
            // Has no effect if request has already started executing.
            previousFetchRequest.priority = .high
            
        } else if let scheduleDay = scheduleDayProvider.fetchScheduleDayFromCache(for: er, on: date) {
            // Load from cache
            cell.configure(for: scheduleDay)
            
        } else {
            // Get range of dates in month for this cell
            let datesInMonth = date.datesInMonth
            
            // Get FetchRequest for range and store to prevent future attempts for the same section
            fetchRequests[indexPath.section] = scheduleDayProvider.fetchScheduleDays(
                for: er,
                on: datesInMonth,
                resultQueue: OperationQueue.main)
            { (result) in
                
                // Remove requests for dates
                self.fetchRequests[indexPath.section] = nil
                
                let indexPathsToRefresh = datesInMonth.map { self.indexPath(for: $0)! }
                
                indexPathsToRefresh.forEach { indexPathToRefresh in
                    let cellToRefresh = tableView.cellForRow(at: indexPathToRefresh) as? ScheduleDayCell
                    let dateToRefresh = self.date(for: indexPathToRefresh)
                    
                    switch result {
                    case .failure(let error as SnowError):
                        switch error {
                        case .operationCancelled:
                            // Do nothing? Or set to loading?
                            break
                            
                        default:
                            cellToRefresh?.configure(for: dateToRefresh, with: error)
                        }
                    case .failure(let error):
                        cellToRefresh?.configure(for: dateToRefresh, with: error)
                        
                    case .success(let scheduleDays):
                        guard let scheduleDay = scheduleDays.filter({ $0.date == dateToRefresh }).first else { break }
                        cellToRefresh?.configure(for: scheduleDay)
                    }
                }
            }
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath)
    {
        // Prevent re-prioritization of still visible cells by confirming different section number.
        let visibleIndexPaths = tableView.indexPathsForVisibleRows!
        let visibleSections = visibleIndexPaths.map { $0.section }
        guard visibleSections.contains(indexPath.section) == false else { return }
        
        // Re-prioritized if possible
        guard var fetchRequest = fetchRequests[indexPath.section] else { return }
        fetchRequest.priority = .normal
    }
    
    // MARK: Saving
    
    func saveAndUpdateCellForScheduleDay(_ scheduleDay: ScheduleDay) {
        
        let date = scheduleDay.date
        
        // Mark as saving.
        saveRequestDates.insert(date)
        
        // Set cell to 'Saving' if visible
        guard let indexPath = indexPath(for: date) else { return }
        
        let cell = tableView.cellForRow(at: indexPath) as? ScheduleDayCell
        cell?.configure(for: date, as: .Saving)
        
        scheduleDayProvider.save(
            scheduleDay,
            resultQueue: OperationQueue.main)
        { (result) in
            
            // Successfully saved
            self.saveRequestDates.remove(date)
            
            let cell = self.tableView.cellForRow(at: indexPath) as? ScheduleDayCell
            cell?.configure(for: date, as: .Saving)
            
            switch result {
            case .failure(let error):
                cell?.configure(for: date, with: error)
                
            case .success(let scheduleDays):
                guard let scheduleDay = scheduleDays.first else {
                    print("Error: Could not access saved ScheduleDay.")
                    return
                }
                
                cell?.configure(for: scheduleDay)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func todayTapped(_ sender: AnyObject) {
        scrollTable(to: today, position: .top, animated: true)
    }
    
    // MARK: - Segues
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showScheduleDayDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow else {
                print("Could not access selected indexPath.")
                return false
            }
            
            let date = self.date(for: indexPath)
            return scheduleDayProvider.fetchScheduleDayFromCache(for: er, on: date) != nil
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showScheduleDayDetail" {
            let vc = segue.destination as! ScheduleDayDetailVC
            let indexPath = tableView.indexPathForSelectedRow!
            let date = self.date(for: indexPath)
            let scheduleDay = scheduleDayProvider.fetchScheduleDayFromCache(for: er, on: date)!
            
            vc.scheduleDay = scheduleDay
            self.lastSelectedScheduleDay = scheduleDay
        }
    }
}
