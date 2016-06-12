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
    var emergencyRoomProvider: EmergencyRoomProvider = EmergencyRoomService.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Properties
    var ers = [ER]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        ers = emergencyRoomProvider.emergencyRooms.sort { $0.name < $1.name }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(reloadERs),
            name: Notification.LocalDatastoreUpdatedWithNewData,
            object: nil
        )
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Helpers
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func reloadERs() {
        ers = emergencyRoomProvider.emergencyRooms.sort { $0.name < $1.name }
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
