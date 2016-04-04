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
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Helpers
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleDays.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("scheduleDayCell", forIndexPath: indexPath) as! ScheduleDayCell
        
        let scheduleDay = scheduleDays[indexPath.row]
        cell.configureScheduleDay(scheduleDay)
        
        return cell
    }

}
