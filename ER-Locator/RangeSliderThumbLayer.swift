//
//  RangeSliderThumbLayer.swift
//  RangeSlider
//
//  Created by Jeffrey Fulton on 2016-04-08.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

class RangeSliderThumbLayer: CALayer {
    
    // MARK: - Properties
    
    var highlighted = false {
        didSet { setNeedsDisplay() }
    }
    weak var rangeSlider: RangeSlider?
    
    /// Center of the frame.
    var center: CGPoint {
        return CGPoint(
            x: frame.origin.x + (frame.width / 2),
            y: frame.origin.y + (frame.height / 2)
        )
    }
    
    // MARK: - Drawing
    
    override func drawInContext(ctx: CGContext) {
        guard let slider = rangeSlider else {
            print("\(#function): RangeSlider could not be accessed.")
            return
        }
        
        let inset = (slider.thumbWidth - slider.thumbKnobWidth) / 2.0
        let thumbFrame = bounds.insetBy(dx: inset, dy: inset)
        let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
        
        // Inner shadow first so it appears 'under' outer shadow & thumbknob
        let innerShadowColor = UIColor(white: 0.0, alpha: 0.15)
        let innerShadowInset: CGFloat = 1
        let innerShadowFrame = thumbFrame.insetBy(dx: innerShadowInset, dy: innerShadowInset)
        let innerShadowPath = UIBezierPath(roundedRect: innerShadowFrame, cornerRadius: cornerRadius)
        CGContextSetShadowWithColor(
            ctx,
            CGSize(width: 0.0, height: 4.0),
            2,
            innerShadowColor.CGColor
        )
        CGContextAddPath(ctx, innerShadowPath.CGPath)
        CGContextFillPath(ctx)
        
        // Outer shadow
        let outerShadowColor = UIColor(white: 0.0, alpha: 0.15)
        CGContextSetShadowWithColor(
            ctx,
            CGSize(width: 0.0, height: 4.0),
            10,
            outerShadowColor.CGColor
        )
        CGContextFillPath(ctx)
        
        // Fill
        CGContextSetFillColorWithColor(ctx, slider.thumbTintColor.CGColor)
        CGContextAddPath(ctx, thumbPath.CGPath)
        CGContextFillPath(ctx)
        
        
        // Outline
        let outlineColor = UIColor(white: 0.0, alpha: 0.1)
        CGContextSetStrokeColorWithColor(ctx, outlineColor.CGColor)
        CGContextSetLineWidth(ctx, 0.1)
        CGContextAddPath(ctx, thumbPath.CGPath)
        CGContextStrokePath(ctx)        
    }
}
