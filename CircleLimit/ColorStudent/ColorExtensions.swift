//
//  Extensions.swift
//  ColorStudent
//
//  Created by Jeremy Kahn on 10/27/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

// MARK: Conversions between numbers
func controlValueToInterval<T: Comparable>(value: T, min minimum: T, max maximum: T) -> T {
    return max(minimum, min(maximum, value))
}


extension CGFloat {
    var double: Double {
        return Double(self)
    }
    
    var float: Float {
        return Float(self)
    }
    
    func controlledToInterval(minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
        return controlValueToInterval(self, min: minimum, max: maximum)
    }
}

extension Int {
    var double: Double {
        return Double(self)
    }
    
    var float: Float {
        return Float(self)
    }
    
    var cg: CGFloat {
        return CGFloat(self)
    }
    
}

extension CGPoint {
    
    var abs: CGFloat {
        return sqrt(x * x + y * y)
    }
    
    var abs2: CGFloat {
        return x * x + y * y
    }
    
    func transformedBy(transform: CGAffineTransform) -> CGPoint {
        return CGPointApplyAffineTransform(self, transform)
    }
}

extension Float {
    var cg: CGFloat {
        return CGFloat(self)
    }
}

extension Double {
    var cg: CGFloat {
        return CGFloat(self)
    }
}



// MARK: Array operations

extension Array {
    func rotatedBy(k: Int) -> Array<Element> {
        let n = self.count
        var newArray = self
        for i in 0..<n {
            newArray[i] = self[(i + k) % n]
        }
        return newArray
    }
}

// MARK: Color operations

extension UIColor {
    
    var rgba: (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
    
    func asIfWithAlpha(alpha: CGFloat) -> UIColor {
        let (r, g, b, _) = rgba
        return UIColor(red: r * alpha, green: g * alpha, blue: b * alpha, alpha: 1)
    }
    
    func withAlpha(alpha: CGFloat) -> UIColor {
        let (r, g, b, _) = rgba
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
    
    var alpha: CGFloat {
        let (_, _, _, _alpha) = rgba
        return _alpha
    }
}


// MARK: CGPoint arithmetic

func *(left: CGFloat, right: CGPoint) -> CGPoint {
    return CGPoint(x: left * right.x, y: left * right.y)
}

func /(left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func dotProduct(left: CGPoint, _ right: CGPoint) -> CGFloat {
    return left.x * right.x + left.y * right.y
}

// MARK: CGAffineTransform Operations

// Returns a transform that first performs 'left' and then 'right'
func *(left: CGAffineTransform, right: CGAffineTransform) -> CGAffineTransform {
    return CGAffineTransformConcat(left, right)
}


