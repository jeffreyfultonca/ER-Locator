//
//  RangeSlider.swift
//  RangeSlider
//
//  Created by Jeffrey Fulton on 2016-04-08.
//  Copyright © 2016 Jeffrey Fulton. All rights reserved.
//

import UIKit

// TODO: Use generics and protocols to make this control truely reusable/testable.
// TODO: Properly document functionality and usage.
// TODO: Investigate packaging into single file or similar for easy inclusion in other projects... Investigate Swift Package Manager?

/**
 Mimicks a UISlider in apperance and functionality but adds a second thumb target for selecting a range of values rather than just one.
 */
@IBDesignable
class RangeSlider: UIControl {
    
    // MARK: - Properties
    
    private let minValue = 0.0
    private let maxValue = 1.0
    var lowerValue = 0.0
    var upperValue = 1.0
    
    /// Represents the Date component; ignoring time
    var date: NSDate = NSDate()
    
    /// An NSDate used to determine time; date component is ignored when setting this value.
    /// Date component from RangeSlider.date property is used when getting this value.
    var lowerTime: NSDate? {
        get { return dateForValue(lowerValue) }
        set {
            lowerValue = valueForDate(newValue) ?? minValue
            self.updateLayerFrames()
        }
    }
    /// An NSDate used to determine time; date component is ignored when setting this value.
    /// Date component from RangeSlider.date property is used when getting this value.
    var upperTime: NSDate? {
        get { return dateForValue(upperValue) }
        set {
            upperValue = valueForDate(newValue) ?? maxValue
            self.updateLayerFrames()
        }
    }
    
    private let totalMins: Int = 60 * 24
    
    // Must be evenly divisible by 60 else default of 1 used.
    var minuteInterval: Int = 30 {
        didSet {
            guard 60 % minuteInterval == 0 else {
                minuteInterval = oldValue
                return
            }
        }
    }
    
    private var steps: Int { return totalMins / minuteInterval }
    
    private var touchPointXOffset: CGFloat = 0
    
    // MARK: Drawing
    
    private let trackHeight: CGFloat = 2
    let thumbWidth: CGFloat = 44
    let thumbKnobWidth: CGFloat = 27
    
    private let trackLayer = RangeSliderTrackLayer()
    private let lowerThumbLayer = RangeSliderThumbLayer()
    private let upperThumbLayer = RangeSliderThumbLayer()
    
    /// Used to determine priority of draw and highlight.
    /// Important when overlapping occurs.
    private var lastThumbLayerHighlighted: RangeSliderThumbLayer!
    
    // MARK: Appearance
    
    var trackTintColor = UIColor(white: 0.75, alpha: 1.0)
    var trackHighlightTintColor: UIColor { return tintColor }
    var thumbTintColor = UIColor.whiteColor()
    
    var curvaceousness: CGFloat = 1.0
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureLayers()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        configureLayers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }
    
    func configureLayers() {
        // Track Layer
        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(trackLayer)
        
        //Thumb Layers
        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(lowerThumbLayer)
        
        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.mainScreen().scale
        layer.addSublayer(upperThumbLayer)
        
        // Set default state
        lastThumbLayerHighlighted = lowerThumbLayer
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: thumbWidth)
    }
    
    // MARK: - Helpers
    
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.frame = CGRect(
            x: 0,
            y: (bounds.height / 2) - (trackHeight / 2),
            width: bounds.width,
            height: trackHeight
        )
        trackLayer.setNeedsDisplay()
        
        // Lower
        let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
        lowerThumbLayer.frame = CGRect(
            x: lowerThumbCenter - (thumbWidth / 2.0),
            y: (bounds.height / 2) - (thumbWidth / 2),
            width: thumbWidth,
            height: thumbWidth
        )
        lowerThumbLayer.setNeedsDisplay()
        
        // Upper
        let upperThumbCenter = CGFloat(positionForValue(upperValue))
        upperThumbLayer.frame = CGRect(
            x: upperThumbCenter - (thumbWidth / 2.0),
            y: (bounds.height / 2) - (thumbWidth / 2),
            width: thumbWidth,
            height: thumbWidth
        )
        upperThumbLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func positionForValue(value: Double) -> Double {
        return Double(bounds.width - thumbKnobWidth) * (value - minValue) / (maxValue - minValue) + Double(thumbKnobWidth / 2.0)
    }
    
    func valueForPosition(position: CGFloat) -> Double {
        return Double(position - (thumbKnobWidth / 2.0) ) / Double(bounds.width - thumbKnobWidth)
    }
    
    // Prevent value from going below min or above max.
    func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        let maxLower = max( value, lowerValue )
        return min( maxLower, upperValue )
    }
    
    func steppedValue(value: Double) -> Double {
        let stepDouble = Double(steps) * value
        let step = round(stepDouble)
        let steppedValue = step/Double(steps)
        
        return steppedValue
    }
    
    func dateForValue(value: Double) -> NSDate {
        return NSDate(timeInterval: value * Double(totalMins) * 60, sinceDate: date.beginningOfDay)
    }
    
    func valueForDate(date: NSDate?) -> Double? {
        guard let date = date else { return nil }
        
        let secondsSinceBeginningOfDay = date.timeIntervalSinceDate(self.date.beginningOfDay)
        let minutesSinceBeginningOfDay = secondsSinceBeginningOfDay / 60
        let value = minutesSinceBeginningOfDay / Double(totalMins)
        
        return value
    }

    
    // MARK: - UIControl
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let touchPoint = touch.locationInView(self)
        
        // Give priority to last highlighted thumb layer incase they are overlapping.
        let otherThumbLayer: RangeSliderThumbLayer
        
        if lastThumbLayerHighlighted == lowerThumbLayer {
            otherThumbLayer = upperThumbLayer
        } else {
            otherThumbLayer = lowerThumbLayer
        }
        
        // Hit test thumb layers
        
        if lastThumbLayerHighlighted.frame.contains(touchPoint) {
            lastThumbLayerHighlighted.highlighted = true
        }
        else if otherThumbLayer.frame.contains(touchPoint) {
            otherThumbLayer.highlighted = true
            lastThumbLayerHighlighted = otherThumbLayer
        }
        
        // zPosition
        lowerThumbLayer.zPosition = lowerThumbLayer.highlighted ? 1.0 : 0.0
        upperThumbLayer.zPosition = upperThumbLayer.highlighted ? 1.0 : 0.0
        
        // Set touchPointOffsetX
        touchPointXOffset = lastThumbLayerHighlighted.center.x - touchPoint.x
        
        // This should probably be clearer...
        return lastThumbLayerHighlighted.highlighted
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let touchPoint = touch.locationInView(self)
        
        // Calc value for location?
        let position = touchPoint.x + touchPointXOffset
        let newValue = valueForPosition(position)
        
        // Update the values
        if lowerThumbLayer.highlighted {
            let bound = boundValue(newValue, toLowerValue: minValue, upperValue: upperValue)
            let stepped = steppedValue(bound)
            
            // Only update lowerValue if changed
            guard lowerValue != stepped else { return true }
            
            lowerValue = stepped
        }
        else if upperThumbLayer.highlighted {
            let bound = boundValue(newValue, toLowerValue: lowerValue, upperValue: maxValue)
            let stepped = steppedValue(bound)
            
            // Only update upperValue if changed
            guard upperValue != stepped else { return true }
            
            upperValue = stepped
        }
        
        // Update the UI
        updateLayerFrames()
        
        sendActionsForControlEvents(.ValueChanged)
        
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        lastThumbLayerHighlighted.highlighted = false
    }
}