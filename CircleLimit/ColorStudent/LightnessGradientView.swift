//
//  LightnessGradientView.swift
//  ColorStudent
//
//  Created by Jeremy Kahn on 10/14/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

@IBDesignable
class LightnessGradientView: UIView {
    
    // We have to use an explicit optional in order to use IBDesignable
    var dataSource: TriangleViewController?
    
    var colorChoice: ColorChoiceParameters {
        return dataSource?.colorChoice ?? ColorChoiceParameters()
    }
    
    var lightness: CGFloat {
        return dataSource?.lightness ?? 1
    }
    
    var sizeMultiplier: CGFloat {
        return dataSource?.dynamicSizeMultiplier ?? 1
    }
    
    // The intended distance in the view, in points, between the start and end of the gradient
    var size: CGFloat {
        return bounds.width * max(0.1, sizeMultiplier * colorChoice.centerColorWeight)
    }
    
    var currentTransform: CGAffineTransform {
        let innerTranslation = CGAffineTransform(translationX: -lightness, y: 0)
        let rescaling = CGAffineTransform(scaleX: size, y: 1)
        let outerTranslation = CGAffineTransform(translationX: bounds.width/2, y: 0)
        return innerTranslation * rescaling * outerTranslation
    }
    
    var farStartPoint: CGPoint {
        return CGPoint(x: -100, y: 0)
    }
    
    var startPoint: CGPoint {
        return CGPoint(x: 0, y: 0)
    }
    
    var endPoint: CGPoint {
        return CGPoint(x: 1, y: 0)
    }
    
    var farEndPoint: CGPoint {
        return CGPoint(x: 101, y: 0)
    }
    
    var startColor: UIColor {
        return colorChoice.colorWithCenterColor(UIColor.black)
    }
    
    var endColor: UIColor {
        return colorChoice.colorWithCenterColor(UIColor.white)
    }
    
    
    override func draw(_ rect: CGRect) {
        let currentContext = UIGraphicsGetCurrentContext()
        currentContext?.concatenate(currentTransform)
        drawGradient(fromPoint: startPoint, toPoint: endPoint, fromColor: startColor, toColor: endColor)
        // Cheesy way to complete the gradient at the two ends
        drawColorBar(fromPoint: endPoint, toPoint: farEndPoint, withColor: endColor)
        drawColorBar(fromPoint: farStartPoint, toPoint: startPoint, withColor: startColor)
    }

}
