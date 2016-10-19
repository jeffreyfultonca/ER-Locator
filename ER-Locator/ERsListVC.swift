//
//  ERsListVC.swift
//  ER-Locator
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
    var erProvider: ERProviding = ERProvider.sharedInstance
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Properties
    var ers = [ER]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        ers = erProvider.ers.sorted { $0.name < $1.name }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadERs),
            name: .localDatastoreUpdatedWithNewData,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Helpers
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func reloadERs() {
        ers = erProvider.ers.sorted { $0.name < $1.name }
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "erCell", for: indexPath)
        
        let er = ers[indexPath.row]
        cell.textLabel?.text = er.name
        
        return cell
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showScheduleDays" {
            if let scheduleDaysVC = segue.destination as? ScheduleDaysVC,
                let selectedIndex = tableView.indexPathForSelectedRow
            {
                scheduleDaysVC.er = ers[selectedIndex.row]
            }
        }
    }
}
