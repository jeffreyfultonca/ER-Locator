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
    
    var firstTimeSlotView: TimeSlotView!
    var secondTimeSlotView: TimeSlotView!
    var thirdTimeSlotView: TimeSlotView!
    
    // Lifecycle
    
    override func awakeFromNib() {
        firstTimeSlotView = TimeSlotView(
            stateIndicator: firstStateIndicator,
            stateLabel: firstStateLabel,
            timesLabel: firstTimesLabel
        )
        secondTimeSlotView = TimeSlotView(
            stateIndicator: secondStateIndicator,
            stateLabel: secondStateLabel,
            timesLabel: secondTimesLabel
        )
        thirdTimeSlotView = TimeSlotView(
            stateIndicator: thirdStateIndicator,
            stateLabel: thirdStateLabel,
            timesLabel: thirdTimesLabel
        )
    }
    
    // Helpers
    
    func configureScheduleDay(scheduleDay: ScheduleDay) {
        dayLabel.text = scheduleDay.date.day
        monthLabel.text = scheduleDay.date.month
        
        // ScheduleDay can have up to 2 open times.
        // O = Open, C = Closed.
        // Allows for O, O/C, C/O, C/O/C, O/C/O.
        
        // Hide all.
        hideAllTimeSlots()
        
        switch scheduleDay.openTimeSlots.count {
        case 0: // Closed
            firstTimeSlotView.state = .Closed
            firstTimeSlotView.hidden = false
            
        case 1: // O, O/C, C/O, C/O/C
            guard let openTimeSlot = scheduleDay.openTimeSlots.first else {
                fatalError("Unable to access first openTimeSlot; this should never have occured.")
            }
            
            // O: Open all day
            if openTimeSlot.open == nil && openTimeSlot.close == nil {
                firstTimeSlotView.state = .Open
            }
            
            // O/C
            if let close = openTimeSlot.close where openTimeSlot.open == nil {
                firstTimeSlotView.state = .Open
                firstTimeSlotView.timesLabel.text = "Midnight - \(close.time)"
                
                secondTimeSlotView.state = .Closed
            }
            
            // C/O
            if let open = openTimeSlot.open where openTimeSlot.close == nil {
                firstTimeSlotView.state = .Closed
                
                secondTimeSlotView.state = .Open
                secondTimeSlotView.timesLabel.text = "\(open.time) - Midnight"
            }
            
            // C/O/C
            if let open = openTimeSlot.open, close = openTimeSlot.close {
                firstTimeSlotView.state = .Closed
                
                secondTimeSlotView.state = .Open
                secondTimeSlotView.timesLabel.text = "\(open.time) - \(close.time)"
                
                thirdTimeSlotView.state = .Closed
            }
            
            // if (date is today) && (open == nil || open < now) && (closed == nil || closed > now)
            
        case 2: // O/C/O
            guard let
                firstOpenTimeSlot = scheduleDay.openTimeSlots.first,
                secondOpenTimeSlot = scheduleDay.openTimeSlots.last else
            {
                fatalError("Unable to access first and last openTimeSlots; this should never have occured.")
            }
            
            // O/C/O
            guard let firstClose = firstOpenTimeSlot.close where firstOpenTimeSlot.open == nil else {
                fatalError("Invalid time slot encountered. Open/Closed/Open only valid for 24 ER's. First open slot must start at midnight (represented as nil) and have non-nil close date.")
            }
            
            guard let secondOpen = secondOpenTimeSlot.open where secondOpenTimeSlot.close == nil else {
                fatalError("Invalid time slot encountered. Open/Closed/Open only valid for 24 ER's. Second open slot must have non-nil open date and close at midnight (represented as nil).")
            }
            
            firstTimeSlotView.state = .Open
            firstTimeSlotView.timesLabel.text = "Midnight - \(firstClose.time)"
            
            secondTimeSlotView.state = .Closed
            
            thirdTimeSlotView.state = .Open
            thirdTimeSlotView.timesLabel.text = "\(secondOpen.time) - Midnight"
            
            
        default:
            // Implement an unknown state to protect for future options?
            print("Unknown state...")
        }
    }
    
    private func setHiddenAllTimeSlots(hidden: Bool) {
        firstTimeSlotView.hidden = hidden
        secondTimeSlotView.hidden = hidden
        thirdTimeSlotView.hidden = hidden
    }
    
    private func hideAllTimeSlots() {
        setHiddenAllTimeSlots(true)
    }
    
    private func showAllTimeSlots() {
        setHiddenAllTimeSlots(false)
    }
}

typealias TimeSlot = (open: NSDate?, close: NSDate?)

extension ScheduleDay {
    var openTimeSlots: [TimeSlot] {
        return []
    }
}