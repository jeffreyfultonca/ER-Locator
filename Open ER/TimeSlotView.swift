//
//  TimeSlotView.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-04.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

/**
 Represents a ScheduleDay TimeSlot with state indicator/label, times, and color.
 */
struct TimeSlotView {
    
    // MARK: - State Enum
    enum State: String {
        case Saving
        case Loading
        case Closed
        case Open
        case Error
        
        var color: UIColor {
            switch self {
            case .Saving:
                return UIColor.saving()
            case .Loading:
                return UIColor.loading()
            case .Closed:
                return UIColor.closed()
            case .Open:
                return UIColor.open()
            case .Error:
                return UIColor.warning()
            }
        }
    }
    
    // MARK: - Stored Properties
    
    var stateIndicator: UIView
    var stateLabel: UILabel
    var timesLabel: UILabel
    
    // MARK: - Lifecycle
    
    init(stateIndicator: UIView, stateLabel: UILabel, timesLabel: UILabel) {
        self.stateIndicator = stateIndicator
        self.stateLabel = stateLabel
        self.timesLabel = timesLabel
    }
    
    // MARK: - Computed Properties
    
    /// Determines whether child views are displayed in UI using UIView.hidden property.
    var isHidden: Bool = false {
        didSet {
            stateIndicator.hidden = isHidden
            stateLabel.hidden = isHidden
            timesLabel.hidden = isHidden
        }
    }
    
    /// Determines predefined view characteristics based on State enumerations. i.e. color, label test.
    /// - note: Setting this property automatically sets isHidden property to false.
    var state: State = .Closed {
        didSet {
            stateIndicator.backgroundColor = state.color
            stateLabel.textColor = state.color
            stateLabel.text = state.rawValue
            
            timesLabel.text = nil
            
            isHidden = false
        }
    }
}