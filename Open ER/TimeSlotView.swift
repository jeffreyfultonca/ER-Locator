//
//  TimeSlotView.swift
//  Open ER
//
//  Created by Jeffrey Fulton on 2016-04-04.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class TimeSlotView {
    
    // MARK: - Properties
    
    var stateIndicator: UIView
    var stateLabel: UILabel
    var timesLabel: UILabel
    
    init(stateIndicator: UIView, stateLabel: UILabel, timesLabel: UILabel) {
        self.stateIndicator = stateIndicator
        self.stateLabel = stateLabel
        self.timesLabel = timesLabel
    }
    
    var hidden: Bool = false {
        didSet {
            stateIndicator.hidden = hidden
            stateLabel.hidden = hidden
            timesLabel.hidden = hidden
        }
    }
    
    // MARK: - State
    enum State: String {
        case Loading
        case Closed
        case Open
        case Error
        
        var color: UIColor {
            switch self {
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
    
    var state: State = .Closed {
        didSet {
            stateIndicator.backgroundColor = state.color
            stateLabel.textColor = state.color
            stateLabel.text = state.rawValue
            
            timesLabel.text = nil
            
            hidden = false
        }
    }
}