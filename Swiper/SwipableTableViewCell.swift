//
//  SwipableTableViewCell.swift
//  CellButtons
//
//  Created by Vegard Solheim Theriault on 12/07/15.
//  Copyright © 2015 Vegard Solheim Theriault. All rights reserved.
//

import UIKit

protocol SwipableTableViewCellDelegate {
    func swipableTableViewCellDidAcceptWithCell(cell: UITableViewCell)
    func swipableTableViewCellDidDeclineWithCell(cell: UITableViewCell)
}

class SwipableTableViewCell: UITableViewCell {

    
    // -------------------------------
    // MARK: Public Properties
    // -------------------------------
    
    var delegate: SwipableTableViewCellDelegate?
    
    var acceptColor: UIColor = UIColor(red:   0.0   / 255.0,
                                       green: 186.0 / 255.0,
                                       blue:  17.0  / 255.0,
                                       alpha: 1.0) {
        didSet {
            guard let acceptLayer = acceptLayer else { return }
            acceptLayer.backgroundColor = acceptColor.CGColor
        }
    }
    
    var declineColor: UIColor = UIColor(red:   236.0 / 255.0,
                                        green: 0.0   / 255.0,
                                        blue:  0.0   / 255.0,
                                        alpha: 1.0) {
        didSet {
            guard let declineLayer = declineLayer else { return }
            declineLayer.backgroundColor = declineColor.CGColor
        }
    }
    
    
    
    // -------------------------------
    // MARK: Private Properties
    // -------------------------------
    
    private var declineLayer: CALayer!
    private var acceptLayer:  CALayer!
    
    private var acceptConfirmationIndicator:  CAShapeLayer!
    private var declineConfirmationIndicator: CAShapeLayer!
    
    private var acceptConfirmationIndicatorIsShowing  = false
    private var declineConfirmationIndicatorIsShowing = false
    
    private var hasBeenAwokenFromNib = false
    
    private var panRecognizer: UIPanGestureRecognizer!
    
    
    
    
    // -------------------------------
    // MARK: Private Constants
    // -------------------------------
    
    private struct SwipingValue {
        static let RatioForSnapping:                 CGFloat = 0.3 // Affects how far across the screen a cell needs to be swiped to be selected
        static let RubberCoefficient:                CGFloat = 4   // Affects how much rubber-effect the cell will have when it's been swiped far enough
        static let ConfirmationAccelerationExponent: CGFloat = 4   // Affects how fast the selection layer will catch up to the cell content when swiped
    }
    
    private struct SpringAnimationValue {
        static let Stiffness:       CGFloat = 300
        static let Damping:         CGFloat = 17
        static let InitialVelocity: CGFloat = 10
    }
    
    private struct ConfirmationIndicatorValue {
        static let Inset:               CGFloat = 16.0 // The distance the indicator will be from the edge of the cell
        static let WidthToHeightRatio:  CGFloat = 0.7  // Width of the confirmation indicator as a percentage of the indicator height
        static let HeightRatio:         CGFloat = 0.5  // Height of the confirmation indicator as a percentage of cell height.
        static let DrawingTime:  CFTimeInterval = 0.2  // The time it takes to draw the confirmation indicators
    }
    
    private struct AnimationKey {
        static let MoveAcceptToCompletion               = "MoveAcceptToCompletion"
        static let MoveLayerToAcceptCompletion          = "MoveLayerToAcceptCompletion"
        static let MoveDeclineToCompletion              = "MoveDeclineToCompletion"
        static let MoveLayerToDeclineCompletion         = "MoveLayerToDeclineCompletion"
        
        static let FadeInAcceptConfirmationIndicator    = "FadeInAcceptConfirmationIndicator"
        static let FadeInDeclineConfirmationIndicator   = "FadeInDeclineConfirmationIndicator"
        static let FadeOutAcceptConfirmationIndicator   = "FadeOutAcceptConfirmationIndicator"
        static let FadeOutDeclineConfirmationIndicator  = "FadeOutDeclineConfirmationIndicator"
        
        static let MoveBackCellAnimation                = "MoveBackCellAnimation"
        static let MoveBackDeclineAnimation             = "MoveBackDeclineAnimation"
        static let MoveBackAcceptAnimation              = "MoveBackAcceptAnimation"
    }
    
    private struct AnimationProperty {
        static let StrokeEnd = "strokeEnd"
        static let PositionX = "position.x"
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Life Cycle
    // -------------------------------
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        hasBeenAwokenFromNib = true
        
        selectionStyle = UITableViewCellSelectionStyle.None
        panRecognizer = UIPanGestureRecognizer(target: self, action: Selector("panning:"))
        panRecognizer.delegate = self
        contentView.addGestureRecognizer(panRecognizer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Cancels the current pan if there is one
        if panRecognizer != nil {
            panRecognizer.enabled = false
            panRecognizer.enabled = true
        }
        
        resetAllLayers()
        addLayers()
    }
    
    
    // Includes removing the added layers
    private func resetAllLayers() {
        if declineLayer != nil {
            declineLayer.removeFromSuperlayer()
            declineLayer = nil
        }
        if acceptLayer != nil {
            acceptLayer.removeFromSuperlayer()
            acceptLayer = nil
        }
        if acceptConfirmationIndicator != nil {
            acceptConfirmationIndicator.removeFromSuperlayer()
            acceptLayer = nil
        }
        if declineConfirmationIndicator != nil {
            declineConfirmationIndicator.removeFromSuperlayer()
            declineConfirmationIndicator = nil
        }
        
        contentView.layer.position = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
    }
    
    private func addLayers() {
        if hasBeenAwokenFromNib == true && declineLayer == nil && acceptLayer == nil {
            addSelectionLayers()
            addConfirmationIndicatorLayers()
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Add Layers
    // -------------------------------
    
    private func addSelectionLayers() {
        acceptLayer = CALayer()
        
        // Workaround for the fact that the layers are visible while rotating
        // The color will be set when the pan gesture is in state .Began
        acceptLayer!.backgroundColor = UIColor.clearColor().CGColor
        acceptLayer!.frame = CGRect(x:  -bounds.size.width,
                                    y:  0,
                                width:  bounds.size.width,
                                height: bounds.size.height)
        layer.addSublayer(acceptLayer!)
        
        declineLayer = CALayer()
        
        // Workaround for the fact that the layers are visible while rotating
        // The color will be set when the pan gesture is in state .Began
        declineLayer!.backgroundColor = UIColor.clearColor().CGColor
        declineLayer!.frame = CGRect(x:  bounds.size.width,
                                     y:  0,
                                 width:  bounds.size.width,
                                 height: bounds.size.height)
        layer.addSublayer(declineLayer!)
    }
    
    private func addConfirmationIndicatorLayers() {
        let indicatorHeight = self.bounds.size.height * ConfirmationIndicatorValue.HeightRatio
        let indicatorWidth  = indicatorHeight * ConfirmationIndicatorValue.WidthToHeightRatio
        
        let acceptFrame = CGRect(x: ConfirmationIndicatorValue.Inset,
                                 y: ((1.0 - ConfirmationIndicatorValue.HeightRatio) * self.bounds.size.height) / 2,
                             width: indicatorWidth,
                            height: indicatorHeight)
        
        let acceptPath = UIBezierPath()
        acceptPath.moveToPoint(   CGPoint(x: 0,                          y: acceptFrame.size.height * 0.6))
        acceptPath.addLineToPoint(CGPoint(x: acceptFrame.size.width / 3, y: acceptFrame.size.height))
        acceptPath.addLineToPoint(CGPoint(x: acceptFrame.size.width,     y: 0))
        
        acceptConfirmationIndicator             = CAShapeLayer()
        acceptConfirmationIndicator.frame       = acceptFrame
        acceptConfirmationIndicator.fillColor   = UIColor.clearColor().CGColor
        acceptConfirmationIndicator.path        = acceptPath.CGPath
        acceptConfirmationIndicator.strokeColor = UIColor.whiteColor().CGColor
        acceptConfirmationIndicator.lineWidth   = 2
        acceptConfirmationIndicator.strokeEnd   = 0.0
        
        self.layer.addSublayer(acceptConfirmationIndicator)
        
        
        
        let declineFrame = CGRect(x: self.bounds.size.width - ConfirmationIndicatorValue.Inset - indicatorWidth,
                                  y: ((1.0 - ConfirmationIndicatorValue.HeightRatio) * self.bounds.size.height) / 2,
                              width: indicatorWidth,
                             height: indicatorHeight)
        
        let declinePath = UIBezierPath()
        declinePath.moveToPoint(   CGPoint(x: 0,                       y: 0))
        declinePath.addLineToPoint(CGPoint(x: declineFrame.size.width, y: declineFrame.size.height))
        declinePath.moveToPoint(   CGPoint(x: 0,                       y: declineFrame.size.height))
        declinePath.addLineToPoint(CGPoint(x: declineFrame.size.width, y: 0))
        
        declineConfirmationIndicator             = CAShapeLayer()
        declineConfirmationIndicator.frame       = declineFrame
        declineConfirmationIndicator.fillColor   = UIColor.clearColor().CGColor
        declineConfirmationIndicator.path        = declinePath.CGPath
        declineConfirmationIndicator.strokeColor = UIColor.whiteColor().CGColor
        declineConfirmationIndicator.lineWidth   = 2
        declineConfirmationIndicator.strokeEnd   = 0.0
        
        self.layer.addSublayer(declineConfirmationIndicator)
    }
    
    
    
    
    // -------------------------------
    // MARK: Pan Gesture Recognizer
    // -------------------------------
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panRecognizer {
            let translation = panRecognizer.translationInView(self)
            if abs(translation.x) > abs(translation.y) {
                return true
            }
        }
        return false
    }
    
    func panning(recognizer: UIPanGestureRecognizer) {
        if isAnimating == false {
            switch recognizer.state {
            case .Began:
                // Workaround for the fact that the layers are visible while rotating
                // The color will be set to clearColor as part of the layoutSubviews() call
                acceptLayer?.backgroundColor = acceptColor.CGColor
                declineLayer?.backgroundColor = declineColor.CGColor
            case .Changed:
                let x = layersXPositionForPansTranslationInView(recognizer.translationInView(self))
                let y = bounds.size.height / 2
                
                if recognizer.translationInView(self).x > 0 { // Is declining
                    // Make sure the decline button is properly hidden
                    declineLayer.position = CGPoint(x: bounds.size.width * 1.5, y: bounds.size.height / 2)
                    expandAcceptLayerToX(x)
                } else { // Is declining
                    // Make sure the accept button is properly hidden
                    acceptLayer.position = CGPoint(x: -(bounds.size.width / 2), y: bounds.size.height / 2)
                    expandDeclineLayerToX(x)
                }
                contentView.layer.position = CGPoint(x: x, y: y)
                
            case UIGestureRecognizerState.Ended:
                if translationIsFarEnoughToSnap(recognizer.translationInView(self)) {
                    // Move to whichever button was selected
                    if contentView.layer.position.x > bounds.size.width / 2 {
                        animateToAccept()
                    } else {
                        animateToDecline()
                    }
                } else {
                    
                    if contentView.layer.position.x > bounds.size.width / 2 {
                        animateAcceptBackToStart()
                    } else {
                        animateDeclineBackToStart()
                    }
                    
                    animateSwiperBackToStart()
                }
            case UIGestureRecognizerState.Cancelled: fallthrough
            case UIGestureRecognizerState.Failed:
                animateSwiperBackToStart()
            default:
                break
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Animate Back to Default Position
    // -------------------------------
    
    private func animateSwiperBackToStart() {
        let from = Double(contentView.layer.position.x)
        let to   = Double(bounds.size.width) / 2
        
        let animation = moveBackAnimationWithFromValue(from, andToValue: to)
        
        contentView.layer.setValue(NSNumber(double: to), forKeyPath: AnimationProperty.PositionX)
        contentView.layer.addAnimation(animation, forKey: AnimationKey.MoveBackCellAnimation)
    }
    
    private func animateDeclineBackToStart() {
        removeDeclineConfirmationIndicator()
        
        let from = Double(declineLayer.position.x)
        let to   = Double(bounds.size.width * 1.5)
        
        let animation = moveBackAnimationWithFromValue(from, andToValue: to)
        
        declineLayer.setValue(NSNumber(double: to), forKeyPath: AnimationProperty.PositionX)
        declineLayer.addAnimation(animation, forKey: AnimationKey.MoveBackDeclineAnimation)
    }
    
    private func animateAcceptBackToStart() {
        removeAcceptConfirmationIndicator()
        
        let from = Double(acceptLayer.position.x)
        let to   = Double(bounds.size.width / 2 * -1)
        
        let animation = moveBackAnimationWithFromValue(from, andToValue: to)
        
        acceptLayer.setValue(NSNumber(double: to), forKeyPath: AnimationProperty.PositionX)
        acceptLayer.addAnimation(animation, forKey: AnimationKey.MoveBackAcceptAnimation)
    }
    
    private func moveBackAnimationWithFromValue(fromValue: Double, andToValue toValue: Double) -> CASpringAnimation {
        let animation               = CASpringAnimation(keyPath: AnimationProperty.PositionX)
        animation.toValue           = NSNumber(double: toValue)
        animation.fromValue         = NSNumber(double: fromValue)
        animation.stiffness         = SpringAnimationValue.Stiffness
        animation.damping           = SpringAnimationValue.Damping
        animation.initialVelocity   = SpringAnimationValue.InitialVelocity
        animation.duration          = animation.settlingDuration
        
        return animation
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Animate to Completion
    // -------------------------------
    
    private var declineCompletionAnimation: CABasicAnimation?
    private var acceptCompletionAnimation:  CABasicAnimation?
    
    private func animateToAccept() {
        let acceptLayerFrom = Double(acceptLayer.position.x)
        let acceptLayerTo   = Double(bounds.size.width / 2)
        let acceptAnimation = completionAnimationWithFromValue(acceptLayerFrom, andToValue: acceptLayerTo)
        
        acceptLayer.setValue(NSNumber(double: acceptLayerTo), forKeyPath: AnimationProperty.PositionX)
        acceptLayer.addAnimation(acceptAnimation, forKey: AnimationKey.MoveAcceptToCompletion)
        
        let layerFrom = Double(layer.position.x)
        let layerTo   = Double(bounds.size.width * 1.5)
        acceptCompletionAnimation = completionAnimationWithFromValue(layerFrom, andToValue: layerTo)
        acceptCompletionAnimation?.removedOnCompletion = false
        acceptCompletionAnimation!.delegate = self
        
        contentView.layer.setValue(NSNumber(double: layerTo), forKeyPath: AnimationProperty.PositionX)
        contentView.layer.addAnimation(acceptCompletionAnimation!, forKey: AnimationKey.MoveLayerToAcceptCompletion)
    }
    
    private func animateToDecline() {
        let declineLayerFrom = Double(declineLayer.position.x)
        let declineLayerTo   = Double(bounds.size.width / 2)
        let declineAnimation = completionAnimationWithFromValue(declineLayerFrom, andToValue: declineLayerTo)
        
        declineLayer.setValue(NSNumber(double: declineLayerTo), forKeyPath: AnimationProperty.PositionX)
        declineLayer.addAnimation(declineAnimation, forKey: AnimationKey.MoveDeclineToCompletion)
        
        let layerFrom       = Double(contentView.layer.position.x)
        let layerTo         = Double(bounds.size.width / 2 * -1)
        declineCompletionAnimation  = completionAnimationWithFromValue(layerFrom, andToValue: layerTo)
        declineCompletionAnimation?.removedOnCompletion = false
        declineCompletionAnimation!.delegate = self
        
        contentView.layer.setValue(NSNumber(double: layerTo), forKeyPath: AnimationProperty.PositionX)
        contentView.layer.addAnimation(declineCompletionAnimation!, forKey: AnimationKey.MoveLayerToDeclineCompletion)
    }
    
    private func completionAnimationWithFromValue(fromValue: Double, andToValue toValue: Double) -> CABasicAnimation {
        let animation            = CABasicAnimation(keyPath: AnimationProperty.PositionX)
        animation.toValue        = NSNumber(double: toValue)
        animation.fromValue      = NSNumber(double: fromValue)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animation.duration       = 0.15
        
        return animation
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if flag {
            if let animation = contentView.layer.animationForKey(AnimationKey.MoveLayerToAcceptCompletion) where animation == anim {
                // Did finish accepting
                delegate?.swipableTableViewCellDidAcceptWithCell(self)
            } else if let animation = contentView.layer.animationForKey(AnimationKey.MoveLayerToDeclineCompletion) where animation == anim {
                // Did finish declining
                delegate?.swipableTableViewCellDidDeclineWithCell(self)
            }
        }
    }
    
    
    
    
    // -------------------------------
    // MARK: Expanding the Layers
    // -------------------------------
    
    private func expandAcceptLayerToX(xInput: CGFloat) {
        guard let acceptLayer = acceptLayer else { return }
        let normalizedXInput = xInput - (bounds.size.width / 2)
        
        let destination = bounds.size.width * SwipingValue.RatioForSnapping
        let progress = normalizedXInput / destination
        
        var normalizedXToExpandTo = normalizedXInput
        if progress < 1 {
            let acceptLayerProgress = pow(progress, SwipingValue.ConfirmationAccelerationExponent)
            normalizedXToExpandTo = destination * acceptLayerProgress
            
            removeAcceptConfirmationIndicator()
        } else {
            addAcceptConfirmationIndicator()
        }
        
        let xToExpandTo = normalizedXToExpandTo - (bounds.size.width / 2)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        acceptLayer.position.x = xToExpandTo
        CATransaction.commit()
    }
    
    private func expandDeclineLayerToX(xInput: CGFloat) {
        guard let declineLayer = declineLayer else { return }

        let snapDistance = bounds.size.width * SwipingValue.RatioForSnapping
        
        let progress = 1 - (xInput - ((bounds.size.width / 2) - snapDistance)) / snapDistance

        var declineLayerDistanceMoved = bounds.size.width / 2 - xInput
        if progress < 1 {
            let declineLayerProgress = pow(progress, SwipingValue.ConfirmationAccelerationExponent)
            declineLayerDistanceMoved = snapDistance * declineLayerProgress
            
            removeDeclineConfirmationIndicator()
        } else {
            addDeclineConfirmationIndicator()
        }
        
        let newDeclineLayerX = bounds.size.width * 1.5 - declineLayerDistanceMoved
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        declineLayer.position.x = newDeclineLayerX
        CATransaction.commit()
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Draw Completion Indicators
    // -------------------------------

    private func addAcceptConfirmationIndicator() {
        if acceptConfirmationIndicatorIsShowing == false {
            acceptConfirmationIndicatorIsShowing = true
            
            let fadeInAnimation = CABasicAnimation(keyPath: AnimationProperty.StrokeEnd)
            if let presentationStrokeEnd = acceptConfirmationIndicator.presentationLayer()?.strokeEnd {
                fadeInAnimation.fromValue = NSNumber(double: Double(presentationStrokeEnd))
            } else {
                fadeInAnimation.fromValue = NSNumber(double: Double(acceptConfirmationIndicator.strokeEnd))
            }
            fadeInAnimation.toValue = NSNumber(double: 1.0)
            fadeInAnimation.duration = ConfirmationIndicatorValue.DrawingTime
            
            acceptConfirmationIndicator.setValue(NSNumber(double: 1.0), forKey: AnimationProperty.StrokeEnd)
            acceptConfirmationIndicator.addAnimation(fadeInAnimation, forKey: AnimationKey.FadeInAcceptConfirmationIndicator)
        }
    }
    
    private func addDeclineConfirmationIndicator() {
        if declineConfirmationIndicatorIsShowing == false {
            declineConfirmationIndicatorIsShowing = true
            
            let fadeInAnimation = CABasicAnimation(keyPath: AnimationProperty.StrokeEnd)
            if let presentationStrokeEnd = declineConfirmationIndicator.presentationLayer()?.strokeEnd {
                fadeInAnimation.fromValue = NSNumber(double: Double(presentationStrokeEnd))
            } else {
                fadeInAnimation.fromValue = NSNumber(double: Double(declineConfirmationIndicator.strokeEnd))
            }
            fadeInAnimation.toValue = NSNumber(double: 1.0)
            fadeInAnimation.duration = ConfirmationIndicatorValue.DrawingTime
            
            declineConfirmationIndicator.setValue(NSNumber(double: 1.0), forKey: AnimationProperty.StrokeEnd)
            declineConfirmationIndicator.addAnimation(fadeInAnimation, forKey: AnimationKey.FadeInDeclineConfirmationIndicator)
        }
    }
    
    private func removeAcceptConfirmationIndicator() {
        if acceptConfirmationIndicatorIsShowing == true {
            acceptConfirmationIndicatorIsShowing = false
            
            let fadeOutAnimation = CABasicAnimation(keyPath: AnimationProperty.StrokeEnd)
            if let presentationStrokeEnd = acceptConfirmationIndicator.presentationLayer()?.strokeEnd {
                fadeOutAnimation.fromValue = NSNumber(double: Double(presentationStrokeEnd))
            } else {
                fadeOutAnimation.fromValue = NSNumber(double: Double(acceptConfirmationIndicator.strokeEnd))
            }
            fadeOutAnimation.toValue = NSNumber(double: 0.0)
            fadeOutAnimation.duration = ConfirmationIndicatorValue.DrawingTime
            
            acceptConfirmationIndicator.setValue(NSNumber(double: 0.0), forKey: AnimationProperty.StrokeEnd)
            acceptConfirmationIndicator.addAnimation(fadeOutAnimation, forKey: AnimationKey.FadeOutAcceptConfirmationIndicator)
        }
    }
    
    private func removeDeclineConfirmationIndicator() {
        if declineConfirmationIndicatorIsShowing == true {
            declineConfirmationIndicatorIsShowing = false
            
            let fadeOutAnimation = CABasicAnimation(keyPath: AnimationProperty.StrokeEnd)
            if let presentationStrokeEnd = declineConfirmationIndicator.presentationLayer()?.strokeEnd {
                fadeOutAnimation.fromValue = NSNumber(double: Double(presentationStrokeEnd))
            } else {
                fadeOutAnimation.fromValue = NSNumber(double: Double(declineConfirmationIndicator.strokeEnd))
            }
            fadeOutAnimation.toValue = NSNumber(double: 0.0)
            fadeOutAnimation.duration = ConfirmationIndicatorValue.DrawingTime
            
            declineConfirmationIndicator.setValue(NSNumber(double: 0.0), forKey: AnimationProperty.StrokeEnd)
            declineConfirmationIndicator.addAnimation(fadeOutAnimation, forKey: AnimationKey.FadeOutDeclineConfirmationIndicator)
        }
    }
    
    
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private var isAnimating: Bool {
        get {
            if let
                contentLayerKeys = contentView.layer.animationKeys(),
                declineLayerKeys = declineLayer.animationKeys(),
                acceptLayerKeys  = acceptLayer.animationKeys()
                where
                contentLayerKeys.count > 0 ||
                declineLayerKeys.count > 0 ||
                acceptLayerKeys.count  > 0
            {
                return true
            } else {
                return false
            }
        }
    }
    
    private func layersXPositionForPansTranslationInView(translationInView: CGPoint) -> CGFloat {
        if !translationIsFarEnoughToSnap(translationInView) {
            return bounds.size.width / 2 + translationInView.x
        } else {
            var nonRestrictedPart = bounds.size.width * SwipingValue.RatioForSnapping
            if translationInView.x < 0 {
                nonRestrictedPart *= -1
            }
            let restrictedPart = (translationInView.x - nonRestrictedPart) / SwipingValue.RubberCoefficient
            
            return bounds.size.width / 2 + nonRestrictedPart + restrictedPart
        }
    }
    
    private func translationIsFarEnoughToSnap(translationInView: CGPoint) -> Bool {
        return abs(translationInView.x) > SwipingValue.RatioForSnapping * bounds.size.width
    }
    
}
