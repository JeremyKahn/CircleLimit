//
//  HyperbolicDot.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 7/19/15.
//  Copyright (c) 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

class HPoint : Equatable {
    
    init() { self.z = 0.i }
    
    init(_ z: Complex64) {self.z = z}
    
    var z: Complex64
    
    var abs: Double {
        return z.abs
    }
    
    var arg: Double {
        return z.arg
    }
    
    var re: Double {
        return z.re
    }
    
    var im: Double {
        return z.im
    }
    
    var distanceToOrigin: Double {
        return absToDistance(z.abs)
    }
    
    var cgPoint: CGPoint {
        return CGPoint(x: z.re, y: z.im)
    }
    
    lazy var moveSelfToOrigin: HyperbolicTransformation = {
        return HyperbolicTransformation(a: self)
    }()
    
    func distanceTo(z: HPoint) -> Double {
        return moveSelfToOrigin.appliedTo(z).distanceToOrigin
    }
    
    func liesWithin(cutoff: Double) -> (HPoint -> Bool) {
        let absCutoff = distanceToAbs(cutoff)
        let M = moveSelfToOrigin
        return { return M.appliedTo($0).abs < absCutoff }
    }
    
    func distanceToLineThroughOriginAnd(b: HPoint) -> Double {
        let theta = b.arg - self.arg
        let sinhH = sin(theta) * absToSinhDistance(abs)
        return asinh(sinhH.abs)
    }
    
    func distanceToLineThrough(a: HPoint, _ b: HPoint) -> Double {
        let newB = a.moveSelfToOrigin.appliedTo(b)
        let newSelf = a.moveSelfToOrigin.appliedTo(self)
        return newSelf.distanceToLineThroughOriginAnd(newB)
    }
    
    func distanceToArcThrough(a: HPoint, _ b: HPoint) -> Double {
        if a.angleBetween(self, b).abs > Double.PI / 2 {
            return distanceTo(a)
        } else if b.angleBetween(self, a).abs > Double.PI / 2 {
            return distanceTo(b)
        }
            return distanceToLineThrough(a, b)
        }
    
    func angleBetween(a: HPoint, _ b: HPoint) -> Double {
        let newA = moveSelfToOrigin.appliedTo(a)
        let newB = moveSelfToOrigin.appliedTo(b)
        return angleAtOriginBetween(newA, newB)
    }

}

func ==(lhs: HPoint, rhs: HPoint) -> Bool {
    return lhs.z == rhs.z
}

func angleAtOriginBetween(a: HPoint, _ b: HPoint) -> Double {
    var theta = a.arg - b.arg
    theta = theta > Double.PI ? theta - 2 * Double.PI : theta
    theta = theta < -Double.PI ? theta + 2 * Double.PI : theta
    return theta
}

func absToSinhDistance(a: Double) -> Double {
    return 2 * a / (1 - a * a)
}

func absToDistance(a: Double) -> Double {
    return log((1 + a)/(1 - a))
}

func distanceToAbs(d: Double) -> Double {
    let e = exp(d)
    return (e-1)/(e+1)
}

//func distanceFromOrigin(z: HPoint) -> Double {
//    return absToDistance(z.abs)
//}
//
//func distanceBetween(z: HPoint,w: HPoint) -> Double {
//    let M = HyperbolicTransformation(a: z)
//    return distanceFromOrigin(M.appliedTo(w))
//}

//extension HPoint {
//
//    func hyperbolicDistanceToOrigin() -> Double {
//        return distanceFromOrigin(self)
//    }
//
//}

extension Double {
    var degrees:  Int {
        return Int(360 * self/(2 * M_PI))
    }
}



func geodesicArcCenterRadiusStartEnd(a: HPoint, b: HPoint) -> (Complex64, Double, Double, Double, Bool) {
    let M = HyperbolicTransformation(a: a)
    let M_inverse = M.inverse()
    let bPrime = M.appliedTo(b)
    var (u, v) = (-bPrime.z/bPrime.abs, bPrime.z/bPrime.abs)
    (u, v) = (M_inverse.appliedTo(u), M_inverse.appliedTo(v))
    var theta = 0.5 * (v/u).arg
    var (aa, bb) = (a, b)
    var swapped = false
    if theta < 0 {
        swap(&u, &v)
        swap(&aa, &bb)
        theta = -theta
        swapped = true
    }
    let radius = tan(theta)
    let center = Complex(abs: 1/cos(theta), arg: u.arg + theta)
    let start = (aa.z-center).arg
    let end = (bb.z-center).arg
    return (center, radius, start, end, swapped)
}

func approximatingCubicBezierToCircularArc(center: Complex64, radius: Double, start: Double, end: Double, swapped: Bool) -> (Complex64, Complex64) {
    var theta = (end - start).abs
    if theta > Double.PI {
        theta = 2 * Double.PI - theta
    }
    let h = magicNumber(theta)
    let startPoint = center + radius * exp(start.i)
    let startControl = startPoint + radius * h * exp(start.i - Double.PI.i/2)
    let endPoint = center + radius * exp(end.i)
    let endControl = endPoint + radius * h * exp(end.i + Double.PI.i/2)
    return swapped ? (endControl, startControl) : (startControl, endControl)
}

func controlPointsForApproximatingCubicBezierToGeodesic(a: HPoint, b: HPoint) -> (Complex64, Complex64) {
    let (center, radius, start, end, swapped) = geodesicArcCenterRadiusStartEnd(a, b: b)
    let (startControl, endControl) = approximatingCubicBezierToCircularArc(center, radius: radius, start: start, end: end, swapped: swapped)
    return (startControl, endControl)
}

func magicNumber(theta: Double) -> Double {
    return (4.0/3.0) * tan(theta / 4)
}

func pointForComplex(z: Complex64) -> CGPoint {
    return CGPoint(x: z.re, y: z.im)
}

