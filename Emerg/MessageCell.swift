//
//  MessageCell.swift
//  Emerg
//
//  Created by Jeffrey Fulton on 2016-06-07.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

/// Shows message when other information is not available. i.e. Loading data when no cached data available.
class MessageCell: UITableViewCell {
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
}
