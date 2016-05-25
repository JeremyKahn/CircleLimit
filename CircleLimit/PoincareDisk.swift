//
//  HyperbolicDot.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 7/19/15.
//  Copyright (c) 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

class HPoint : Equatable, CustomStringConvertible {
    
    init() { self.z = 0.i }
    
    init(_ z: Complex64) {
        self.z = z
    }
    
    var z: Complex64
    
    var description: String {
        return z.nice
    }
    
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
        let accuracy = 0.000001
        if a.distanceTo(b) < accuracy {
            return distanceTo(a)
        }
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

func isocelesAltitudeFromSideLength(l: Double, andAngle angle: Double) -> Double {
    // u is sinh the half-length of opposite side
    let shL = sinh(l)
    let (c, s) = (cos(angle/2), sin(angle/2))
    let sinhAltitude =  c * shL / sqrt(1 + s * s * shL * shL)
    return asinh(sinhAltitude)
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


// This fails to distinguish geodesics through the origin
// But it works quite well for _disjoint_ geodesics
struct HeuristicGeodesic: Locatable, Matchable {
    
    typealias Location = IntArray
    
    static let multiplier: Double = 64 * 1024
    
    static let tolerance: Double = pow(2, -15)
    
    private var sumOfEndpoints: Complex64
    
    var endPoints: (Complex64, Complex64)
    
    var location: Location {
        let a = [sumOfEndpoints.re, sumOfEndpoints.im]
        return IntArray(values: a.map() {Int($0 * HeuristicGeodesic.multiplier)})
    }
    
    static func neighbors(place: Location) -> [Location] {
        return place.neighbors
    }
    
    init(_ a: Complex64, _ b: Complex64) {
        sumOfEndpoints = a + b
        endPoints = (a, b)
    }
    
    init(_ a: HPoint, _ b: HPoint) {
        let (u, v) = endPointsOfGeodesicThrough(a, b)
        self.init(u, v)
    }
    
    init(v: HTrans) {
        let w = v.following(HTrans.goForward(1))
        self.init(v.appliedToOrigin, w.appliedToOrigin)
    }
    
    func matches(y: HeuristicGeodesic) -> Bool {
        return (sumOfEndpoints - y.sumOfEndpoints).abs < HeuristicGeodesic.tolerance
    }
    
    func transformedBy(M: HTrans) -> HeuristicGeodesic {
        let (a, b) = endPoints
        return HeuristicGeodesic(M.appliedTo(a), M.appliedTo(b))
    }
 
    var approximateDistanceToOrigin: Double {
        return 0.5 * log(16/(4 - sumOfEndpoints.abs2))
    }
}


func endPointsOfGeodesicThrough(a: HPoint, _ b:HPoint) -> (Complex64, Complex64) {
    let M = HyperbolicTransformation(a: a)
    let M_inverse = M.inverse
    let bPrime = M.appliedTo(b)
    var (u, v) = (-bPrime.z/bPrime.abs, bPrime.z/bPrime.abs)
    (u, v) = (M_inverse.appliedTo(u), M_inverse.appliedTo(v))
    return (u, v)
}

func geodesicArcCenterRadiusStartEnd(a: HPoint, b: HPoint) -> (Complex64, Double, Double, Double, Bool) {
    var (u, v) = endPointsOfGeodesicThrough(a, b)
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

// THIS FAILS when a == 0 or b == 0
func controlPointsForApproximatingCubicBezierToGeodesic(a: HPoint, b: HPoint) -> (Complex64, Complex64) {
    let (center, radius, start, end, swapped) = geodesicArcCenterRadiusStartEnd(a, b: b)
    let (startControl, endControl) = approximatingCubicBezierToCircularArc(center, radius: radius, start: start, end: end, swapped: swapped)
    return (startControl, endControl)
}

func addGeodesicFrom(a: HPoint, to b: HPoint) -> (UIBezierPath -> ()) {
    let threshhold = 0.001
    var makeLine = false
    if a.abs < threshhold || b.abs < threshhold {
        makeLine = true
    } else {
        let r = a.z/b.z
        let rr = r/r.abs
        makeLine = ((rr - 1).abs) < threshhold || ((rr + 1).abs < threshhold)
    }
    if makeLine {
        return { $0.addLineToPoint(b.cgPoint) }
    } else {
        let (startControl, endControl) = controlPointsForApproximatingCubicBezierToGeodesic(a, b: b)
        let (startHControl, endHControl) = (pointForComplex(startControl), pointForComplex(endControl))
        return { $0.addCurveToPoint(b.cgPoint, controlPoint1: startHControl, controlPoint2: endHControl) }
    }
}

func magicNumber(theta: Double) -> Double {
    return (4.0/3.0) * tan(theta / 4)
}

func pointForComplex(z: Complex64) -> CGPoint {
    return CGPoint(x: z.re, y: z.im)
}

