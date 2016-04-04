//
//  ERCell.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit
import CoreLocation

class ERCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var hoursLabel: UILabel!
    @IBOutlet var estWaitTimeLabel: UILabel!
    
    // MARK: - Helpers
    
    func configureER(er: ER, fromLocation location: CLLocation?) {
        // Name
        nameLabel.text = er.name
        
        // Distance
        if let location = location {
            let distanceInMeters = er.location.distanceFromLocation(location)
            distanceLabel.text = String.localizedStringWithFormat("%.1f km", distanceInMeters / 1000)
        } else {
            distanceLabel.text = "???"
        }
        
        // Hours open
        hoursLabel.text = er.hoursOpen
        
        // Estimated Wait Time
        estWaitTimeLabel.text = er.estimatedWaitTime
    }

//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

}
