//
//  ScheduleDayDetailVC.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-04-07.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class ScheduleDayDetailVC: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var closedImageView: UIImageView!
    @IBOutlet var customImageView: UIImageView!
    
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
        configurePresentControls()
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
    
    func configurePresentControls() {
        for imageView in [closedImageView, customImageView] {
            let tintColor = imageView.tintColor
            imageView.tintColor = nil
            imageView.tintColor = tintColor
        }
    }
    
    func configureRangeSliders() {
        firstTimeSlotRangeSlider.date = scheduleDay.date
    }
    
    // MARK: - Update helpers

    func updateTextFields() {
        firstOpenTextField.text = scheduleDay.firstOpen?.time ?? "N/A"
        firstCloseTextField.text = scheduleDay.firstClose?.time ?? "N/A"
    }
    
    func updateRangeSliders() {
        firstTimeSlotRangeSlider.lowerTime = scheduleDay.firstOpen
        firstTimeSlotRangeSlider.upperTime = scheduleDay.firstClose
    }

    // MARK: - Actions
    
    @IBAction func open24Tapped(sender: AnyObject) {
        scheduleDay.firstOpen = scheduleDay.date.beginningOfDay
        scheduleDay.firstClose = scheduleDay.date.endOfDay
        
        updateTextFields()
        updateRangeSliders()
    }
    
    @IBAction func open12Tapped(sender: AnyObject) {
        scheduleDay.firstOpen = scheduleDay.date.atHour(8)
        scheduleDay.firstClose = scheduleDay.date.atHour(20)
        
        updateTextFields()
        updateRangeSliders()
    }
    
    @IBAction func closedTapped(sender: AnyObject) {
        scheduleDay.firstOpen = nil
        scheduleDay.firstClose = nil
        
        updateTextFields()
        updateRangeSliders()
    }
    
    
    @IBAction func rangeSliderValueChanged(rangeSlider: RangeSlider) {
        let firstOpen = rangeSlider.lowerTime
        let firstClosed = rangeSlider.upperTime
        
        // Update ScheduleDay properties
        scheduleDay.firstOpen = firstOpen
        scheduleDay.firstClose = firstClosed
        
        updateTextFields()
    }
}
