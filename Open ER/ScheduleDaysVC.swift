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
    var scheduleDays = [ScheduleDay]()
    var scheduleDaysLoaded = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard er != nil else { fatalError("er dependency not met.") }
        
        setupTableView()
        
        erService.fetchScheduleDaysForER(er) { result in
            switch result {
            case .Failure(let error):
                print(error)
                
            case .Success(let scheduleDays):
                self.scheduleDays = scheduleDays
                self.scheduleDaysLoaded = true
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Helpers
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 65
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard scheduleDaysLoaded else { return 0 }
        return 365
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("scheduleDayCell", forIndexPath: indexPath) as! ScheduleDayCell
        
        let row = indexPath.row
        let scheduleDay: ScheduleDay
        
        if row < scheduleDays.count {
            // Existing record
            scheduleDay = scheduleDays[indexPath.row]
            
        } else {
            // Create new with defaults
            let earliestDate = scheduleDays.first?.date ?? NSDate.now
            let date = earliestDate.plusDays(row)
            scheduleDay = ScheduleDay(date: date)
            scheduleDays.append(scheduleDay)
        }
        
        cell.configureScheduleDay(scheduleDay)
        
        return cell
    }

}
