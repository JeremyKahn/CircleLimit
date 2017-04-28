//
//  PoincareView.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 7/19/15.
//  Copyright (c) 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

typealias GroupSystem = [(HDrawable, [Action])]

protocol PoincareViewDataSource : class {
    
    /// The list of (object, group) pairs
    var groupSystemToDraw: GroupSystem {get}
    
    /// Used to scale the picture
    var multiplier : CGFloat {get}
    
    /// Used to draw the red circle
    var cutoffDistance: Double {get}
}


func circlePath(_ center: CGPoint, radius: CGFloat) -> UIBezierPath {
    let path =  UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: false)
    return path
}

@IBDesignable
class PoincareView: UIView {
    
    // MARK: Flags for testing and debugging
    static var testing = false
    
    var testingIBDesignable = false
    
    var tracingDrawRect = false
    
    var showRedCircle = true
    
    // MARK: From Poincare View Data Source
    weak var dataSource : PoincareViewDataSource!
    
    var groupSystem: GroupSystem {
        return dataSource?.groupSystemToDraw ?? []
    }
    
    var scale: CGFloat {
        return baseScale * (dataSource?.multiplier ?? 1)
    }
    
    var cutoffDistance: Double {
        return dataSource?.cutoffDistance ?? 100
    }
    
    // MARK: Basic parameters from the view
    // The point at the center of view, where we'll put the center of the hyperbolic disk
    var viewCenter: CGPoint {
        return convert(center, from: superview)
    }
    
    // The radius of the view
    var viewRadius: CGFloat {
        return min(bounds.size.width, bounds.size.height)/2
    }

    var baseScale : CGFloat {
        return viewRadius * 0.99
    }

    // MARK: Stuff to draw the blue (boundary) and red (cutoff) circles
    // The line width used to draw the circles
    @IBInspectable
    var lineWidth: CGFloat = 0.01 {
        didSet {setNeedsDisplay()  }
    }
    
    // The color for the boundary circle
    @IBInspectable
    var circleColor = UIColor.blue
    
    let cgturn = CGFloat(2 * Double.pi)
    
     func circlePath(_ center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path =  UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: cgturn, clockwise: false)
        path.lineWidth = lineWidth
        return path
    }
    
    // MARK: The affine transform for the view
    var tf : CGAffineTransform {
        //        println("Scale is now \(scale)")
        let t1 = CGAffineTransform(translationX: viewCenter.x, y: viewCenter.y)
        let t2 = t1.scaledBy(x: scale, y: scale)
        return t2
    }
    
    // MARK: The drawing function
    override func draw(_ rect: CGRect) {
        //        println("entering PoincareView.drawRect with \(objects.count) objects")
 
        if testingIBDesignable { dataSource = nil }
        
        print("\nStarting drawRect", when: tracingDrawRect)
        let startTime = Date()
        
        // Center the graphics context at the origin of the disk and scale according to the zoom scale
        let gcontext = UIGraphicsGetCurrentContext()
        gcontext?.concatenate(tf)

        // Draw the boundary of the hyperbolic disk
        circleColor.set()
        let boundaryCircle = circlePath(CGPoint.zero, radius: CGFloat(1.0))
        boundaryCircle.lineWidth = lineWidth
        boundaryCircle.stroke()
   
        if PoincareView.testing {return}
        
        // for each (object, group) in groupSystem, draw all translates of object by the elements of group
        for (object, group) in groupSystem {
            print("Drawing an object with a group of size \(group.count)", when: tracingDrawRect)
            for action in group {
                     object.drawWithMaskAndAction(action)
            }
        }
        
        // The view controller is supposed to hand the view the objects that intersect a disk of radius cutoffDistance around the origin
        // This draws the boundary of that disk in red
        if showRedCircle {
            UIColor.red.withAlphaComponent(0.75).set()
            let cutoffCircle = circlePath(CGPoint.zero, radius: CGFloat(distanceToAbs(cutoffDistance)))
            cutoffCircle.lineWidth = lineWidth/2
            cutoffCircle.stroke()
        }
        
        let timeToDrawInMilliseconds = Date().timeIntervalSince(startTime) * 1000
        print("Finished with drawRect.  Time taken: \(timeToDrawInMilliseconds.int) ms", when: tracingDrawRect)
    }
}
