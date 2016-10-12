//
//  CenterPoint.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 3/22/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

func centerPointAndRadius(_ points: [HPoint], delta: Double, startingAt startPoint: HPoint) -> (HPoint, Double) {
    guard points.count > 0 else {
        return (HPoint(), 0.0)
    }
    if points.count == 1 {
        return (points[0], 0.0)
    }
    if points.count == 2 {
        return (points[0].midpointTo(points[1]), points[0].distanceTo(points[1])/2)
    }
    var M = HyperbolicTransformation(a: startPoint)
    var movingPoints = points.map { M.appliedTo($0) }
    var finished = false
    var motion: HyperbolicTransformation
    var radius: Double
    var numberOfIterations = 0
    repeat {
        (motion, finished, radius) = wayToShiftFinishedAndRadius(movingPoints, delta: delta)
        movingPoints = movingPoints.map { motion.appliedTo($0) }
        M = motion.following(M)
        numberOfIterations += 1
        if numberOfIterations > 1000 {
            print("Moving points: \(movingPoints)")
            print("motion: \(motion)")
            print("radius: \(radius)")
        }
    } while !finished
    //    print("Number of iterations: \(numberOfIterations)")
    return (M.inverse.appliedTo(HPoint()), radius)
}



func centerPointAndRadius(_ points: [HPoint], delta: Double) -> (HPoint, Double) {
    guard points.count > 0 else {
        return (HPoint(), 0.0)
    }
    return centerPointAndRadius(points, delta: delta, startingAt: points[0])
}

// Right now our goal is not the optimal algorithm
func wayToShiftFinishedAndRadius(_ points: [HPoint], delta: Double) -> (HyperbolicTransformation, Bool, Double) {
    var maxAbs = 0.0
    var indexMax = 0
    for i in 0..<points.count {
        if points[i].abs > maxAbs {
            maxAbs = points[i].abs
            indexMax = i
        }
    }
    let maxDistance = absToDistance(maxAbs)
    if maxDistance < delta {
        return (HyperbolicTransformation(), true, maxDistance)
    }
    let cutoffDistance = maxDistance - delta/2
    let cutoff = distanceToAbs(cutoffDistance)
    var closePoints = points.filter() { $0.abs > cutoff }
    let argMax = points[indexMax].arg
    var shiftedArgs = Array<Double>(repeating: 0, count: closePoints.count)
    for i in 0..<closePoints.count {
        var arg = closePoints[i].arg - argMax
        arg = arg < Double.PI ? arg + 2 * Double.PI : arg
        arg = arg > Double.PI ? arg - 2 * Double.PI : arg
        shiftedArgs[i] = arg
    }
    let maxArg = shiftedArgs.reduce(-Double.PI) { max($0, $1) }
    let minArg = shiftedArgs.reduce(Double.PI) { min($0, $1) }
    let argDiff = maxArg - minArg
    let distance1 = isocelesAltitudeFromSideLength(maxDistance, andAngle: argDiff)
    if distance1 <  delta {
        return (HyperbolicTransformation(), true, maxDistance)
    }
    let distance2 = isocelesAltitudeFromSideLength(cutoffDistance, andAngle: argDiff)
    let distanceToMove = min(distance2, delta/4)
    let avgArg = argMax + (maxArg + minArg)/2
    let a = Complex<Double>(abs: distanceToAbs(distanceToMove), arg: avgArg)
    let M = HyperbolicTransformation(a: a)
    return (M, false, 0)    
}

