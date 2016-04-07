//
//  ERsListVC.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class ERsListVC: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate
{
    // MARK: - Dependencies
    var erService = ERService.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Properties
    var ers = [ER]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        fetchERs()
    }
    
    // MARK: - Helpers
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func fetchERs() {
        // Show loading
        erService.fetchAllERs(failure: processError, success: processERs)
    }
    
    func processError(error: ErrorType) {
        // Hide loading
        
        // TODO: Handler possible errors.
        print(error)
    }
    
    func processERs(ers: [ER]) {
        // Hide loading
        self.ers = ers
        tableView.reloadData()
    }
    
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("erCell", forIndexPath: indexPath)
        
        let er = ers[indexPath.row]
        
        cell.textLabel?.text = er.name
        
        return cell
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showScheduleDays" {
            if let
                scheduleDaysVC = segue.destinationViewController as? ScheduleDaysVC,
                selectedIndex = tableView.indexPathForSelectedRow
            {
                scheduleDaysVC.er = ers[selectedIndex.row]
            }
        }
    }
}
