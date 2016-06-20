//
//  RangeSliderTrackLayer.swift
//  RangeSlider
//
//  Created by Jeffrey Fulton on 2016-04-08.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class RangeSliderTrackLayer: CALayer {
    
    // MARK: - Properties
    
    weak var rangeSlider: RangeSlider?
    
    override func drawInContext(ctx: CGContext) {
        guard let slider = rangeSlider else {
            print("\(#function): RangeSlider could not be accessed.")
            return
        }
        
        // Clip
        let cornerRadius = bounds.height * slider.curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        CGContextAddPath(ctx, path.CGPath)
        
        // Fill the track
        CGContextSetFillColorWithColor(ctx, slider.trackTintColor.CGColor)
        CGContextAddPath(ctx, path.CGPath)
        CGContextFillPath(ctx)
        
        // Fill highlighted range
        CGContextSetFillColorWithColor(ctx, slider.trackHighlightTintColor.CGColor)
        let lowerValuePosition = CGFloat(slider.positionForValue(slider.lowerValue))
        let upperValuePosition = CGFloat(slider.positionForValue(slider.upperValue))
        let rect = CGRect(
            x: lowerValuePosition,
            y: 0.0,
            width: upperValuePosition - lowerValuePosition,
            height: bounds.height
        )
        CGContextFillRect(ctx, rect)
    }
}
