//
//  HyperbolicPolyline.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 3/31/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

class HyperbolicPolyline : HDrawable {
    
    var observingAllChanges = false
    
    var centerPoint = HPoint()
    
    var radius: Double = 0
    
    var points: [HPoint] = [] {
        didSet {
          print("Polygon points now \(points)", when: observingAllChanges)
        }
    }
    
    var mask: HyperbolicTransformation = HyperbolicTransformation()
    
    var maskedPointsToDraw: [HPoint] {
        //        print("Drawing a curve with subsequence: \(activeSubsequence)")
        var maskedPoints = subsequenceOf(points, withIndices: activeSubsequence)
        for i in 0..<maskedPoints.count {
            maskedPoints[i] = mask.appliedTo(maskedPoints[i])
        }
        return maskedPoints
    }
    
    var intrinsicLineWidth = 0.015
    
    var lineColor: UIColor = UIColor.blackColor()
    
    // Feels a little weird to include these in Hyperbolic Polyline: right now they're just included in order to comform to HDrawable
    // TODO: Put these in a separate protocol?
    var fillColorTable: ColorTable = [1: UIColor.blueColor(), 2: UIColor.greenColor(), 3: UIColor.redColor(), 4: UIColor.yellowColor()]
    
    var fillColorBaseNumber = ColorNumber.baseNumber
    
    var fillColor: UIColor = UIColor.clearColor()
    
    var useFillColorTable = true
    
    // MARK: Initializers
    
    init(_ p: HPoint) {
        points = [p]
        update()
    }
    
    init(_ pp: [HPoint]) {
        points = pp
        update()
        complete()
    }
    
    
    
    init(_ a: HyperbolicPolyline) {
        self.points = a.points
        self.lineColor = a.lineColor
        self.intrinsicLineWidth  = a.intrinsicLineWidth
        self.fillColorTable = a.fillColorTable
        self.fillColorBaseNumber = a.fillColorBaseNumber
        self.useFillColorTable = a.useFillColorTable
        update()
        complete()
    }
    
   func copy() -> HDrawable {
        return HyperbolicPolyline(self)
    }
    
    // MARK: Modifiers
    func addPoint(p: HPoint) {
        assert(p.abs <= 1)
        points.append(p)
        updateAndComplete()
    }
    
    func movePointAtIndex(i: Int, to p: HPoint) {
        assert(p.abs <= 1)
        points[i] = p
        updateAndComplete()
    }
    
    func insertPointAfterIndex(i: Int, point: HPoint) {
        assert(point.abs <= 1)
        assert(points.count > i)
        points.insert(point, atIndex: i + 1)
        updateAndComplete()
    }
    
    func insertPointsAfterIndices(instructions: [(Int, HPoint)]) {
        points.insertAfterIndices(instructions)
        updateAndComplete()
    }
    
    func updateAndComplete() {
        update()
        complete()
    }
    
    func update() {
        (centerPoint, radius) = centerPointAndRadius(points, delta: 0.1, startingAt: centerPoint)
    }
    
    // TODO: Remove redundant points from the list of points
    func removeRepeatedPoints() {
        var i = 0
        while i < points.count - 1 {
            if points[i] == points[i + 1] {
                points.removeAtIndex(i + 1)
            } else {
                i += 1
            }
        }
    }
    
    func complete() {
        buildSubsequenceTable()
    }
    
    // MARK: Searching
    var touchable = true
    
    // Actually returns the indices of the nearby points
    func pointsNear(point: HPoint, withMask mask: HyperbolicTransformation, withinDistance distance: Double) -> [Int] {
        guard touchable else { return [] }
        let maskedPoints = points.map { mask.appliedTo($0) }
        let indexArray = [Int](0..<points.count)
        let nearbyPoints = indexArray.filter() { point.distanceTo(maskedPoints[$0]) < distance }
        return nearbyPoints
    }
    
    
    func sidesNear(point: HPoint, withMask mask: HyperbolicTransformation, withinDistance distance: Double) -> [Int] {
        guard touchable else { return [] }
        let maskedPoints = points.map { mask.appliedTo($0) }
        let indexArray = [Int](0..<points.count - 1)
        let nearbySides = indexArray.filter() { point.distanceToArcThrough(maskedPoints[$0], maskedPoints[$0 + 1]) < distance }
        return nearbySides
    }
    

    // MARK:  Drawing
    
    var maxRadius = 1000.0
    
    // For the ambitious: make this a filled region between two circular arcs
    func geodesicArc(a: HPoint, _ b: HPoint) -> UIBezierPath {
        assert(a.abs <= 1 && b.abs <= 1)
        //        println("Drawing geodesic arc from \(a) to \(b)")
        let (center, radius, start, end,_) = geodesicArcCenterRadiusStartEnd(a, b: b)//
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
        path.lineWidth = suitableLineWidth(a, b)
        return path
    }
    
    // This is a tricky problem...really the line width should vary
    func suitableLineWidth(a: HPoint, _ b: HPoint) -> CGFloat {
        let t = ((a.z + b.z)/2).abs
        return CGFloat(intrinsicLineWidth * (1.0 - t * t) / 2)
    }
    
    func draw() {
        //        println("Drawing path for points \(points)")
        lineColor.set()
        let points = maskedPointsToDraw
        if points.count == 1 {
            let dot = HyperbolicDot(center: points[0], radius: intrinsicLineWidth)
            dot.draw()
        }
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
            updateAndComplete()
        }
    }
    
    // MARK: - Getting the subsequence
    static let stepsPerNaturalExponentOfScale: Double = 3
    
    var scaleOfMask : Int {
        let _scaleOfMask = min(Int(0.00001 - HyperbolicPolyline.stepsPerNaturalExponentOfScale * log(1-mask.a.abs)), HyperbolicPolyline.maxScaleIndex)
        //        print("Scale of mask: \(_scaleOfMask)")
        return _scaleOfMask
    }
    
    var activeSubsequence : [Int] {
        let subsequenceIndices = subsequenceTable[scaleOfMask]
        if subsequenceIndices == [] {
            return [Int](0..<points.count)
        } else {
            return subsequenceTable[scaleOfMask]
        }
    }
    

    // MARK: Building the Subsequence Table
    static var initialDistanceToleranceMultiplier = 0.2
    
    var initialDistanceTolerance : Double {
        return intrinsicLineWidth * HyperbolicPolyline.initialDistanceToleranceMultiplier
    }
    
    var distanceTolerance : Double {
        return initialDistanceTolerance * exp(Double(scaleIndex)/HyperbolicPolyline.stepsPerNaturalExponentOfScale)
    }
    
    static var maximumShrinkageFactor: Double = 1
    
    static var maxScaleIndex = Int(log(maximumShrinkageFactor) * stepsPerNaturalExponentOfScale)
    
    var scaleIndex : Int = 0
    
    var subsequenceTable : [[Int]] = [[Int]](count: maxScaleIndex + 1, repeatedValue: [])
    
    struct radialDistanceCache {
        var sinTheta : Double
        var cosTheta : Double
        var sinhDistanceToOrigin : Double
        var coshDistanceToOrigin : Double
        
        init(z : HPoint) {
            let a = z.abs
            if a == 0 {
                sinTheta = 0.0
                cosTheta = 1.0
                sinhDistanceToOrigin = 0.0
                coshDistanceToOrigin = 1.0
            }
            else {
                sinTheta = z.im / a
                cosTheta = z.re / a
                sinhDistanceToOrigin = 2 * a / ( 1 - a * a )
                coshDistanceToOrigin = (1 + a * a)/(1 - a * a)
            }
        }
        
        func sinAngleTo(y: radialDistanceCache) -> Double {
            return sinTheta * y.cosTheta - cosTheta * y.sinTheta
        }
        
        func cosAngleTo(y: radialDistanceCache) -> Double {
            return cosTheta * y.cosTheta + sinTheta * y.sinTheta
        }
        
        func coshDistanceTo(y: radialDistanceCache) -> Double {
            let cosDeltaTheta = cosAngleTo(y)
            return coshDistanceToOrigin * y.coshDistanceToOrigin - sinhDistanceToOrigin * y.sinhDistanceToOrigin * cosDeltaTheta
        }
        
        func distanceFromRadialLineTo(y: radialDistanceCache) -> Double {
            let sinDeltaTheta = sinAngleTo(y)
            let sinhAltitude = y.sinhDistanceToOrigin * sinDeltaTheta.abs
            let coshDistanceToY = coshDistanceTo(y)
            let sinhDistanceToY = sqrt(coshDistanceToY * coshDistanceToY - 1)
            let minSinhAdjancentSides = min(y.sinhDistanceToOrigin, sinhDistanceToY)
            let sinhDistanceFromRadialLineSegmentToY = max(sinhAltitude, minSinhAdjancentSides)
            return asinh(sinhDistanceFromRadialLineSegmentToY)
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
            var normalizedPoints: [radialDistanceCache] = []
            for k in 0..<j {
                let rDC = radialDistanceCache(z: M.appliedTo(points[k]))
                normalizedPoints.append(rDC)
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
//        print(points)
        for i in 0...HyperbolicPolyline.maxScaleIndex {
            scaleIndex = i
            subsequenceTable[i] = simplifyingSubsequenceIndices()
        }
    }
    
    func simplifyingSubsequenceIndices() -> [Int] {
        return bestSequenceTo(points.count - 1, toMinimizeSumOf: { (x: Int, y: Int) -> Int in
            return 1
            }, withConstraint: canReplaceWithStraightLine)
    }
    

}


