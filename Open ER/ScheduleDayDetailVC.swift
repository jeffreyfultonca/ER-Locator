//
//  ScheduleDayDetailVC.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-07.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class ScheduleDayDetailVC: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var firstOpenTextField: UITextField!
    @IBOutlet var firstCloseTextField: UITextField!
    @IBOutlet var firstTimeSlotRangeSlider: RangeSlider!
    
    // MARK: - Properties
    var scheduleDay: ScheduleDay!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard scheduleDay != nil else { fatalError("scheduleDay dependency not met.") }
        
        configureNavBar()
        
        // Make sure firstTimeSlot open and closed are set
        scheduleDay.firstOpen = scheduleDay.firstOpen ?? scheduleDay.date.beginningOfDay
        scheduleDay.firstClose = scheduleDay.firstClose ?? scheduleDay.date.endOfDay
        
        configureRangeSliders()
        
        updateTextFields()
        updateRangeSliders()
    }
    
    // MARK: - Helpers
    
    func configureNavBar() {
        let df = NSDateFormatter()
        df.dateFormat = "MMMM d"
        
        navigationItem.title = df.stringFromDate(scheduleDay.date)
    }
    
    func configureRangeSliders() {
        firstTimeSlotRangeSlider.date = scheduleDay.date
    }

    func updateTextFields() {
        firstOpenTextField.text = scheduleDay.firstOpen?.time
        firstCloseTextField.text = scheduleDay.firstClose?.time
    }
    
    func updateRangeSliders() {
        if let firstOpen = scheduleDay.firstOpen {
            firstTimeSlotRangeSlider.lowerTime = firstOpen
        }
        
        if let firstClose = scheduleDay.firstClose {
            firstTimeSlotRangeSlider.upperTime = firstClose
        }
        
    }

    // MARK: - Actions
    
    @IBAction func rangeSliderValueChanged(rangeSlider: RangeSlider) {
        print("RangeSlider value changed: \(rangeSlider.lowerValue) - \(rangeSlider.upperValue)")
        
        let firstOpen = rangeSlider.lowerTime
        let firstClosed = rangeSlider.upperTime
        
        // Update ScheduleDay properties
        scheduleDay.firstOpen = firstOpen
        scheduleDay.firstClose = firstClosed
        
        updateTextFields()
        
    }
}
