//
//  TriangleViewController.swift
//  ColorStudent
//
//  Created by Jeremy Kahn on 10/11/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit
import GameplayKit

class TriangleViewController: UIViewController {
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localAlpha = delegate.colorToStartWith.alpha
        triangleView.alpha = localAlpha
        lightnessGradientView.alpha = localAlpha
        
        let (centerToStartWith, lightnessToStartWith) = triangleView.locationOfColor(delegate.colorToStartWith)
        (centerX, centerY) = (centerToStartWith.x, centerToStartWith.y)
        lightness = lightnessToStartWith
                
        previewSource.preview.frame = CGRect(origin: CGPointZero, size: previewContainer.frame.size)
        previewContainer.addSubview(previewSource.preview)
        previewSource.applyColorToPreview(chosenFuckingColor)
    }
    
    let maxSlidingDotProduct: CGFloat = 0.9 * sqrt(3)/2
    
    var localAlpha: CGFloat = 0.1
    
    var dynamicSizeMultiplier: CGFloat = 1
    
    let maximumSizeMultiplier: CGFloat = 20
    
    var centerX: CGFloat = 0
    
    var centerY: CGFloat = 0
    
    var lightness: CGFloat = 1
    
    var colorChoice: ColorChoiceParameters {
        return triangleView.colorChoice
    }
    
    var chosenFuckingColor: UIColor {
        return colorChoice.colorWithCenterColor(UIColor(white: lightness, alpha: 1)).withAlpha(localAlpha)
    }
    
    var previewSource: ColorPickerPreviewSource = DefaultColorPickerPreviewSource()
    
    var delegate: ColorPickerDelegate = DefaultColorPickerDelegate()
    
    @IBOutlet weak var previewContainer: UIView!
    
    func updateViews() {
        triangleView.setNeedsDisplay()
        lightnessGradientView.setNeedsDisplay()
        previewSource.applyColorToPreview(chosenFuckingColor)
        previewSource.preview.setNeedsDisplay()
    }
    
    @IBOutlet weak var triangleView: TriangleView! {
        didSet {
            triangleView.dataSource = self
            triangleView.alpha = localAlpha
            triangleView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(TriangleViewController.zoomTriangleView(_:))))
            triangleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(TriangleViewController.moveTriangleView(_:))))
        }
    }
    
    func zoomTriangleView(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            dynamicSizeMultiplier *= gesture.scale
            dynamicSizeMultiplier = dynamicSizeMultiplier.controlledToInterval(1, maximumSizeMultiplier)
            gesture.scale = 1
            updateViews()
        }
    }
    
    func moveTriangleView(gesture: UIPanGestureRecognizer) {
        if gesture.state == .Changed   {
            var translation = gesture.translationInView(triangleView) / triangleView.size
            gesture.setTranslation(CGPointZero, inView: triangleView)
            let oldCenter = CGPoint(x: centerX, y: centerY)
            centerX += -translation.x
            centerY += -translation.y
            
            // We want to keep the center in the hexagon, and allow lateral movement along the boundary
            if colorChoice.centerColorWeight < 0 {
                var finished = false
                for normal in colorChoice.outwardNormalVectors {
                    if -dotProduct(translation, normal) < maxSlidingDotProduct * translation.abs {
                        translation = translation - dotProduct(translation, normal) * normal
                        centerX = oldCenter.x - translation.x
                        centerY = oldCenter.y - translation.y
                        finished = true
                        break
                    }
                }
                if !finished {
                    (centerX, centerY) = (oldCenter.x, oldCenter.y)
                }
            }
            updateViews()
        }
    }
    
    @IBOutlet weak var lightnessGradientView: LightnessGradientView! {
        didSet {
            lightnessGradientView.alpha = localAlpha
            lightnessGradientView.dataSource = self
        }
    }
    
    @IBAction func changeLightnessCenter(gesture: UIPanGestureRecognizer) {
        if gesture.state == .Changed {
            let translation = gesture.translationInView(lightnessGradientView)
            gesture.setTranslation(CGPointZero, inView: lightnessGradientView)
            lightness += -translation.x / lightnessGradientView.size
            lightness = lightness.controlledToInterval(0, 1)
            updateViews()
        }
    }
    
    @IBAction func cancelChosenColor(sender: UITapGestureRecognizer) {
        delegate.applyColorAndReturn(delegate.colorToStartWith)
    }
    
    @IBAction func sendChosenColor(sender: UILongPressGestureRecognizer) {
        delegate.applyColorAndReturn(chosenFuckingColor)
    }
    
    // Is there an easy way to make this animated?
    func resetViews() {
        centerX = 0
        centerY = 0
        dynamicSizeMultiplier = 1
        lightness = 1
        updateViews()
    }
    
    
}
