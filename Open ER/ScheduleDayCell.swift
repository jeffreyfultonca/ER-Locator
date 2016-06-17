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
    
    private func configure(for date: NSDate) {
        // Hide all.
        hideAllTimeSlots()
        
        dayLabel.text = date.dayOrdinalInMonthString
        monthLabel.text = date.monthAbbreviationString
    }
    
    func configure(for date: NSDate, as state: TimeSlotView.State) {
        configure(for: date)
        firstTimeSlotView.state = state
    }
    
    func configure(for date: NSDate, with error: ErrorType) {
        configure(for: date)
        firstTimeSlotView.state = .Error
        firstTimeSlotView.timesLabel.text = "\(error)"
    }
    
    func configure(for scheduleDay: ScheduleDay) {
        configure(for: scheduleDay.date)
        
        // ScheduleDay currently has only a single open timeslot.
        // O = Open, C = Closed.
        // Allows for O, O/C, C/O, C/O/C.
        
        // Closed if firstTimeSlot is nil
        guard let firstTimeSlot = scheduleDay.firstTimeSlot else {
            firstTimeSlotView.state = .Closed
            return
        }
        
        // O, O/C, C/O, or C/O/C
        
        let opening = firstTimeSlot.open
        let closing = firstTimeSlot.close
        
        // O: Open all day
        if opening.isBeginningOfDay && closing.isEndOf(opening) {
            firstTimeSlotView.state = .Open
            firstTimeSlotView.timesLabel.text = "24 Hours"
        }
            // O/C
        else if opening.isBeginningOfDay /* && !closing.isEndOfDay */ {
            firstTimeSlotView.state = .Open
            firstTimeSlotView.timesLabel.text = "\(opening.time) - \(closing.time)"
            
            secondTimeSlotView.state = .Closed
            secondTimeSlotView.stateLabel.text = nil
        }
            // C/O
        else if /* !opening.isBeginningOfDay && */ closing.isEndOf(opening) {
            firstTimeSlotView.state = .Closed
            firstTimeSlotView.stateLabel.text = nil
            
            secondTimeSlotView.state = .Open
            secondTimeSlotView.timesLabel.text = "\(opening.time) - \(closing.time)"
        }
            // C/O/C
        else /* if !opening.isBeginningOfDay && !closing.isEndOfDay */ {
            firstTimeSlotView.state = .Closed
            firstTimeSlotView.stateLabel.text = nil
            
            secondTimeSlotView.state = .Open
            secondTimeSlotView.timesLabel.text = "\(opening.time) - \(closing.time)"
            
            thirdTimeSlotView.state = .Closed
            thirdTimeSlotView.stateLabel.text = nil
        }
        
        return
    }
    
    // MARK: - Helpers
    
    private func setAllTimeSlots(hidden hidden: Bool) {
        firstTimeSlotView.isHidden = hidden
        secondTimeSlotView.isHidden = hidden
        thirdTimeSlotView.isHidden = hidden
    }
    
    private func hideAllTimeSlots() {
        setAllTimeSlots(hidden: true)
    }
    
    private func showAllTimeSlots() {
        setAllTimeSlots(hidden: false)
    }
}