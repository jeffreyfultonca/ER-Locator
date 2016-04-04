//
//  ScheduleDayCell.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-03.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class ScheduleDayCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var monthLabel: UILabel!
    
    @IBOutlet var firstStateIndicator: UIView!
    @IBOutlet var secondStateIndicator: UIView!
    @IBOutlet var thirdStateIndicator: UIView!
    
    @IBOutlet var firstStateLabel: UILabel!
    @IBOutlet var secondStateLabel: UILabel!
    @IBOutlet var thirdStateLabel: UILabel!
    
    @IBOutlet var firstTimesLabel: UILabel!
    @IBOutlet var secondTimesLabel: UILabel!
    @IBOutlet var thirdTimesLabel: UILabel!
    
    // Helpers
    
    func configureScheduleDay(scheduleDay: ScheduleDay) {
        dayLabel.text = scheduleDay.date.day
        monthLabel.text = scheduleDay.date.month
        
        if scheduleDay.date.day == "4" {
//            hide(firstStateIndicator, stateLabel: firstStateLabel, timesLabel: firstTimesLabel)
            hide(secondStateIndicator, stateLabel: secondStateLabel, timesLabel: secondTimesLabel)
            hide(thirdStateIndicator, stateLabel: thirdStateLabel, timesLabel: thirdTimesLabel)
        } else {
            show(firstStateIndicator, stateLabel: firstStateLabel, timesLabel: firstTimesLabel)
            show(secondStateIndicator, stateLabel: secondStateLabel, timesLabel: secondTimesLabel)
            show(thirdStateIndicator, stateLabel: thirdStateLabel, timesLabel: thirdTimesLabel)
        }
        

    }
    
    private func hide(stateIndicator: UIView, stateLabel: UILabel, timesLabel: UILabel) {
        stateIndicator.hidden = true
        stateLabel.hidden = true
        timesLabel.hidden = true
    }
    
    private func show(stateIndicator: UIView, stateLabel: UILabel, timesLabel: UILabel) {
        stateIndicator.hidden = false
        stateLabel.hidden = false
        timesLabel.hidden = false
    }
}
