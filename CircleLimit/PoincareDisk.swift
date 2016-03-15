//
//  HyperbolicDot.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 7/19/15.
//  Copyright (c) 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

typealias HPoint = Complex64

func distanceFromOrigin(z: HPoint) -> Double {
    let x = z.abs
    return log((1 + x)/(1-x))
}

func distanceBetween(z: HPoint,w: HPoint) -> Double {
    let M = HyperbolicTransformation(a: z)
    return distanceFromOrigin(M.appliedTo(w))
    
}

extension Double {
    var degrees:  Int {
        return Int(360 * self/(2 * M_PI))
    }
}

func distanceFromOriginToGeodesicArc(a: HPoint, b: HPoint) -> Double {
    var (aa, bb) = (a, b)
    if (bb/aa).arg < 0 {
        swap(&aa, &bb)
    }
    var (c, r, _, _) = geodesicArcCenterRadiusStartEnd(aa, b: bb)
    if (c/aa).arg < 0 {
        print("Anomoly aa: \(aa.arg.degrees, bb.arg.degrees, c.arg.degrees, (c/aa).arg.degrees)")
        return distanceFromOrigin(aa)
    }
    else if (bb/c).arg < 0 {
         print("Anomoly bb: \(aa.arg.degrees, bb.arg.degrees, c.arg.degrees, (bb/c).arg.degrees)")
        return distanceFromOrigin(bb)
    }
    else {
        c.abs = c.abs - r
        return distanceFromOrigin(c)
    }
}

func distanceOfArcToPoint(start: HPoint, end: HPoint, middle: HPoint) -> Double {
    let M = HyperbolicTransformation(a: middle)
    return distanceFromOriginToGeodesicArc(M.appliedTo(start), b: M.appliedTo(end))
}



func geodesicArcCenterRadiusStartEnd(a: HPoint, b: HPoint) -> (Complex64, Double, Double, Double) {
    let M = HyperbolicTransformation(a: a)
    let M_inverse = M.inverse()
    let bPrime = M.appliedTo(b)
    var (u, v) = (-bPrime/bPrime.abs, bPrime/bPrime.abs)
    (u, v) = (M_inverse.appliedTo(u), M_inverse.appliedTo(v))
    var theta = 0.5 * (v/u).arg
    var (aa, bb) = (a, b)
    if theta < 0 {
        swap(&u, &v)
        swap(&aa, &bb)
        theta = -theta
    }
    let radius = tan(theta)
    let center = Complex(abs: 1/cos(theta), arg: u.arg) * Complex(abs: 1, arg: theta)
    let start = (aa-center).arg
    let end = (bb-center).arg
    return (center, radius, start, end)
}


protocol HDrawable : class {
    
    // Deprecated
    func transformedBy(_: HyperbolicTransformation) -> HDrawable
    
    func draw()
    
    func drawWithMask(_: HyperbolicTransformation)
    
    var size: Double { get set}
    
    var color: UIColor { get set}
    
    var mask: HyperbolicTransformation { get set}
    
 }


class HyperbolicPolyline : HDrawable {
    
    var points: [Complex64] = []
    
    var mask: HyperbolicTransformation = HyperbolicTransformation()
    
    var scaleOfMask : Int {
        return min(Int(0.00001 - log(1-mask.a.abs)), HyperbolicPolyline.maxScaleIndex)
    }
    
    var activeSubsequence : [Int] {
        let subsequenceIndices = subsequenceTable[scaleOfMask]
        if subsequenceIndices == [] {
            return [Int](0..<points.count)
        } else {
            return subsequenceTable[scaleOfMask]
        }
    }
    
    var maskedPointsToDraw: [HPoint] {
        var maskedPoints = subsequenceOf(points, withIndices: activeSubsequence)
        for i in 0..<maskedPoints.count {
            maskedPoints[i] = mask.appliedTo(maskedPoints[i])
        }
        return maskedPoints
    }
    
    var intrinsicLineWidth : Double {
        return size
    }
    
    var size = 0.03
    
    var color = UIColor.purpleColor()
    
    init(_ p: Complex64) {
        points = [p]
    }
    
    init(_ pp: [Complex64]) {
        points = pp
    }
    
    init(_ a: HyperbolicPolyline) {
        self.points = a.points
        self.color = a.color
        self.size  = a.size
    }
    
    func addPoint(p: Complex64) {
        assert(p.abs <= 1)
        points.append(p)
    }
    
    var maxRadius = 1000.0
    
    // MARK - Building the Subsequence Table
    
    func complete() {
        buildSubsequenceTable()
    }
    
    static var initialDistanceToleranceMultiplier = 0.2
    
    var initialDistanceTolerance : Double {
        return size * HyperbolicPolyline.initialDistanceToleranceMultiplier
    }
    
    var distanceTolerance : Double {
        return initialDistanceTolerance * exp(Double(scaleIndex))
    }
    
    static var maxScaleIndex = 6
    
    var scaleIndex : Int = 0
    
    var subsequenceTable : [[Int]] = [[Int]](count: maxScaleIndex + 1, repeatedValue: [])
    
    struct radialDistanceCache {
        var sinTheta : Double
        var cosTheta : Double
        var sinhDistanceToOrigin : Double
        
        init(z : Complex64) {
            let a = z.abs
            if a == 0 {
                sinTheta = 0.0
                cosTheta = 1.0
                sinhDistanceToOrigin = 0.0
            }
            else {
                sinTheta = z.im / a
                cosTheta = z.re / a
                sinhDistanceToOrigin = 2 * a / ( 1 - a * a )
            }
        }
        
        func distanceFromRadialLineTo(y: radialDistanceCache) -> Double {
            let sinDeltaTheta = sinTheta * y.cosTheta - cosTheta * y.sinTheta
            return sinhDistanceToOrigin * sinDeltaTheta.abs
        }
    }
    
    
    
    var canReplaceWithStraightLineCache : [Bool] = []
    
    // this whole trick relies on the particular implemetation of bestSequenceTo
    func canReplaceWithStraightLine(i: Int, _ j: Int) -> Bool {
        if canReplaceWithStraightLineCache.count == j {
            return canReplaceWithStraightLineCache[i]
        }
        else {
            let M = HyperbolicTransformation(a: points[j])
            var normalizedPoints : [radialDistanceCache] = []
            for k in 0..<j {
                normalizedPoints.append(radialDistanceCache(z: M.appliedTo(points[k])))
            }
            // the next line is an idiom to make the array the correct size
            canReplaceWithStraightLineCache = [Bool](count: j, repeatedValue: true)
            for k in 0..<j {
                var canReplaceWithStraightLine = true
                for l in (k+1)..<j {
                    canReplaceWithStraightLine = canReplaceWithStraightLine && normalizedPoints[k].distanceFromRadialLineTo(normalizedPoints[l]) < distanceTolerance
                }
                canReplaceWithStraightLineCache[k] = canReplaceWithStraightLine
            }
            return canReplaceWithStraightLineCache[i]
         }
    }
    
    func buildSubsequenceTable() {
        print(points)
        for i in 0...HyperbolicPolyline.maxScaleIndex {
            scaleIndex = i
            subsequenceTable[i] = simplifyingSubsequenceIndices()
        }
    }
    
    func simplifyingSubsequenceIndices() -> [Int] {
        print("distanceTolerance: \(distanceTolerance)")
        return bestSequenceTo(points.count - 1, toMinimizeSumOf: { (x: Int, y: Int) -> Int in
            return 1
        }, withConstraint: canReplaceWithStraightLine)
    }
    

    // MARK - Drawing
    
    // For the ambitious: make this a filled region between two circular arcs
    func geodesicArc(a: HPoint, _ b: HPoint) -> UIBezierPath {
        assert(a.abs <= 1 && b.abs <= 1)
//        println("Drawing geodesic arc from \(a) to \(b)")
        let (center, radius, start, end) = geodesicArcCenterRadiusStartEnd(a, b: b)//
//        println("Data: \(center, radius, start, end)")
        var path : UIBezierPath
        if radius > maxRadius || radius.isNaN {
            path = UIBezierPath()
            path.moveToPoint(CGPoint(x: a.re, y: a.im))
            path.addLineToPoint(CGPoint(x: b.re, y: b.im))
        } else {
            path = UIBezierPath(arcCenter: CGPoint(x: center.re, y: center.im),
                radius: CGFloat(radius),
                startAngle: CGFloat(start),
                endAngle: CGFloat(end),
                clockwise: false)
        }
        let t = ((a + b)/2).abs
        path.lineWidth = CGFloat(intrinsicLineWidth * (1 - t * t)) // rough guess
        return path
    }
    
    func drawWithMask(mask: HyperbolicTransformation) {
        self.mask = mask
        draw()
    }
    
    func draw() {
        //        println("Drawing path for points \(points)")
        color.set()
        let points = maskedPointsToDraw
        for i in 0..<(points.count - 1) {
            let path = geodesicArc(points[i], points[i+1])
            path.lineCapStyle = CGLineCap.Round
            path.stroke()
        }
    }
    
    func transformedBy(M: HyperbolicTransformation) -> HDrawable {
        let new = HyperbolicPolyline(self)
        new.transformBy(M)
        return new
    }
    
    func transformBy(M: HyperbolicTransformation) {
        for i in 0...(points.count-1) {
            points[i] = M.appliedTo(points[i])
            assert(points[i].abs <= 1)
        }
    }
 }


class HyperbolicDot : HDrawable {
   
    var center: Complex64 = Complex64()
    
    var mask: HyperbolicTransformation = HyperbolicTransformation()
    
    var radius : Double {
        return size
    }
    
    var size = 0.03
    
    var color = UIColor.purpleColor()
    
    init(dot: HyperbolicDot) {
        self.center = dot.center
        self.size  = dot.size
        self.color = dot.color
    }
    
    init(center: Complex64, radius: Double) {
        self.center = center
        self.size = radius
    }
    
    init(center: Complex64) {
        self.center = center
    }
    
    func drawWithMask(mask: HyperbolicTransformation) {
        let dot = self.transformedBy(mask)
        dot.draw()
    }
    
    func draw() {
        let (x, y, r) = poincareDiskCenterRadius()
        let euclDotCenter = CGPoint(x: x, y: y)
        let c = circlePath(euclDotCenter, radius: CGFloat(r))
        color.set()
        c.fill()
     }
    
    func poincareDiskCenterRadius() -> (centerX: Double, centerY: Double, radius: Double) {
        let dotR = center.abs
        let E = (1 + dotR)/(1 - dotR)
        let M = exp(radius)
        let Q0 = M * E
        let tPlus = (Q0 - 1)/(Q0 + 1)
        let Q1 = E / M
        let tMinus = (Q1 - 1)/(Q1 + 1)
        let euclCenterAbs = (tPlus + tMinus)/2
        let euclR = (tPlus - tMinus)/2
//        println("dotR: \(dotR) E: \(E) M: \(M) Q0: \(Q0) Q1: \(Q1) tPlus: \(tPlus) tMinus: \(tMinus)")
        let complexEuclCenter = Complex(abs: euclCenterAbs, arg: center.arg)
        return(complexEuclCenter.re, complexEuclCenter.im, euclR)
    }
    
    func transformBy(M: HyperbolicTransformation) {
        center = M.appliedTo(center)
    }
    
    func transformedBy(M: HyperbolicTransformation) -> HDrawable {
        let dot = HyperbolicDot(dot: self)
        dot.transformBy(M)
        return dot
    }
}
