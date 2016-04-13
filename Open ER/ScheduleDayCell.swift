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
    
    // MARK: - Lifecycle
    
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
    
    // MARK: - Configuration
    
    func configureWithDate(date: NSDate) {
        // Hide all.
        hideAllTimeSlots()
        
        dayLabel.text = date.dayOrdinalInMonthString
        monthLabel.text = date.monthAbbreviationString
    }
    
    func configureWithScheduleDay(scheduleDay: ScheduleDay) {
        configureWithDate(scheduleDay.date)
        
        // ScheduleDay can have up to 2 open times.
        // O = Open, C = Closed.
        // Allows for O, O/C, C/O, C/O/C, O/C/O.
        
        // Closed if firstTimeSlot is nil
        guard let firstTimeSlot = scheduleDay.firstTimeSlot else {
            firstTimeSlotView.state = .Closed
            return
        }
        
        // O, O/C, C/O, or C/O/C if secondTimeSlot is nil
        guard let secondTimeSlot = scheduleDay.secondTimeSlot else {
            let open = firstTimeSlot.open
            let close = firstTimeSlot.close
            
            // O: Open all day
            if open.isBeginningOfDay && close.isEndOf(open) {
                firstTimeSlotView.state = .Open
                firstTimeSlotView.timesLabel.text = "24 Hours"
            }
            // O/C
            else if open.isBeginningOfDay /* && !close.isEndOfDay */ {
                firstTimeSlotView.state = .Open
                firstTimeSlotView.timesLabel.text = "\(open.time) - \(close.time)"
                
                secondTimeSlotView.state = .Closed
            }
            // C/O
            else if /* !open.isBeginningOfDay && */ close.isEndOf(open) {
                firstTimeSlotView.state = .Closed
                
                secondTimeSlotView.state = .Open
                secondTimeSlotView.timesLabel.text = "\(open.time) - \(close.time)"
            }
            // C/O/C
            else /* if !open.isBeginningOfDay && !close.isEndOfDay */ {
                firstTimeSlotView.state = .Closed
                
                secondTimeSlotView.state = .Open
                secondTimeSlotView.timesLabel.text = "\(open.time) - \(close.time)"
                
                thirdTimeSlotView.state = .Closed
            }
            
            return
        }
        
        // O/C/O
        firstTimeSlotView.state = .Open
        firstTimeSlotView.timesLabel.text = "\(firstTimeSlot.open.time) - \(firstTimeSlot.close.time)"
        
        secondTimeSlotView.state = .Closed
        
        thirdTimeSlotView.state = .Open
        thirdTimeSlotView.timesLabel.text = "\(secondTimeSlot.open.time) - \(secondTimeSlot.close.time)"
    }
    
    func configureAsSavingWithDate(date: NSDate) {
        configureWithDate(date)
        
        firstTimeSlotView.state = .Saving
    }
    
    func configureAsLoadingWithDate(date: NSDate) {
        configureWithDate(date)
        
        firstTimeSlotView.state = .Loading
    }
    
    func configureWithError(error: ErrorType, andDate date: NSDate) {
        configureWithDate(date)
        
        firstTimeSlotView.state = .Error
        firstTimeSlotView.timesLabel.text = "\(error)"
    }
    
    func configureAsClosedWithDate(date: NSDate) {
        configureWithDate(date)
        
        firstTimeSlotView.state = .Closed
    }
    
    // MARK: - Helpers
    
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