//
//  PoincareView.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 7/19/15.
//  Copyright (c) 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

protocol PoincareViewDataSource : class {
    var groupSystemToDraw: GroupSystem {get}
    var multiplier : CGFloat {get}
    var cutoffDistance: Double {get}
}


func circlePath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
    let path =  UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: false)
    return path
}

@IBDesignable
class PoincareView: UIView {
    
    
    
    @IBInspectable
    var circleColor = UIColor.blueColor()
    
    var viewCenter: CGPoint {
        return convertPoint(center, fromView: superview)
    }
    
    var viewRadius: CGFloat {
        return min(bounds.size.width, bounds.size.height)/2
    }
    
    @IBInspectable
    var lineWidth: CGFloat = 0.01 {
        didSet {setNeedsDisplay()  }
    }
    
    func circlePath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path =  UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: cgturn, clockwise: false)
        path.lineWidth = lineWidth
        return path
    }
    
    let cgturn = CGFloat(2 * M_PI)
    
    weak var dataSource : PoincareViewDataSource!
    
    var groupSystem: GroupSystem {
        return dataSource?.groupSystemToDraw ?? []
    }
    
    var baseScale : CGFloat {
        return viewRadius * 0.99
    }
    
    var scale: CGFloat {
        return baseScale * (dataSource?.multiplier ?? 1)
    }
    
    var cutoffDistance: Double {
        return dataSource?.cutoffDistance ?? 100
    }
    
    var tf : CGAffineTransform {
        //        println("Scale is now \(scale)")
        let t1 = CGAffineTransformMakeTranslation(viewCenter.x, viewCenter.y)
        let t2 = CGAffineTransformScale(t1, scale, scale)
        return t2
    }
    
    var testingIBDesignable = false
    
    var tracingDrawRect = false
    
    var showRedCircle = true
    
    override func drawRect(rect: CGRect) {
        //        println("entering PoincareView.drawRect with \(objects.count) objects")
 
        if testingIBDesignable { dataSource = nil }
        
        print("\nStarting drawRect", when: tracingDrawRect)
        let startTime = NSDate()
 
        let gcontext = UIGraphicsGetCurrentContext()
        CGContextConcatCTM(gcontext, tf)
 

        for (object, group) in groupSystem {
            
            print("Drawing an object with a group of size \(group.count)", when: tracingDrawRect)
            for action in group {
                     object.drawWithMaskAndAction(action)
            }
        }

        circleColor.set()
        let boundaryCircle = circlePath(CGPointZero, radius: CGFloat(1.0))
        boundaryCircle.lineWidth = lineWidth
        boundaryCircle.stroke()
        
        if showRedCircle {
            // Added to test the new cutoff system
            UIColor.redColor().colorWithAlphaComponent(0.75).set()
            let cutoffCircle = circlePath(CGPointZero, radius: CGFloat(distanceToAbs(cutoffDistance)))
            cutoffCircle.lineWidth = lineWidth/2
            cutoffCircle.stroke()
        }
        
        let timeToDrawInMilliseconds = NSDate().timeIntervalSinceDate(startTime) * 1000
        print("Finished with drawRect.  Time taken: \(timeToDrawInMilliseconds.int) ms", when: tracingDrawRect)
    }
}
