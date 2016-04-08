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
    
    // MARK: - Properties
//    var date: NSDate!
    var date: NSDate! = NSDate()
    
    var scheduleDay: ScheduleDay?
    
    // MARK: DatePickers
    let datePicker1stOpen = UIDatePicker()
    let datePicker1stClose = UIDatePicker()
    let datePicker2ndOpen = UIDatePicker()
    let datePicker2ndClose = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard date != nil else { fatalError("date dependency not met.") }
        
        configureNavBar()
        
        configureDatePickersForTextFields()
    }
    
    // MARK: - Helpers
    
    func configureNavBar() {
        let df = NSDateFormatter()
        df.dateFormat = "MMMM d"
        
        navigationItem.title = df.stringFromDate(date)
    }

    func configureDatePickersForTextFields() {
        // First Open
        addActionToDatePicker(datePicker1stOpen)
        datePicker1stOpen.date = scheduleDay?.firstOpen ?? date
        firstOpenTextField.inputView = datePicker1stOpen
        
        // First Close
        addActionToDatePicker(datePicker1stClose)
        datePicker1stClose.date = scheduleDay?.firstClose ?? date
        firstCloseTextField.inputView = datePicker1stClose
    }
    
    func addActionToDatePicker(datePicker: UIDatePicker) {
        datePicker.datePickerMode = .Time
        datePicker.minuteInterval = 30
        datePicker.addTarget(self, action: #selector(datePickerChanged), forControlEvents: .ValueChanged)
    }
    
    // MARK: - DatePicker
    func datePickerChanged(datePicker: UIDatePicker) {
        switch datePicker {
        case datePicker1stOpen:
            scheduleDay?.firstOpen = datePicker.date
            firstOpenTextField.text = datePicker.date.time
            
        case datePicker1stClose:
            scheduleDay?.firstClose = datePicker.date
            firstCloseTextField.text = datePicker.date.time
            
            
        default:
            print(datePicker.date.description)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
