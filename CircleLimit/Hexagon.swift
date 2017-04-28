//
//  Hexagon.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit


/// Represents either a cuff or a rotation
enum CuffRotation {
    /// A cuff, with a given length
    case cuff(Double)
    
    /// An corner with angle pi/q
    case rotation(Int)
    
    init(complexLength: Complex64) {
        if complexLength.im.abs < 0.0000001 {
            self = CuffRotation.cuff(complexLength.re)
        } else if complexLength.re.abs < 0.0000001 {
            self = CuffRotation.rotation(Int(Double.PI/complexLength.im))
        } else {
            fatalError()
        }
    }
    
    var complexLength: Complex64 {
        switch self {
        case .cuff(let length):
            return length + 0.i
        case .rotation(let p):
            return (Double.PI/Double(p)).i
        }
    }
    
    var rotation: Int {
        switch self {
        case .rotation(let r):
            return r
        case .cuff:
            return 0
        }
    }
}

/// A right angled hexagon in the hyperbolic plane
class Hexagon: Hashable {
    
    // MARK: Basic stored properties
    static var nextId = 0
    
    var id: Int
    
    var hashValue: Int {
        return id
    }
    
    var location: LocationData {
        return LocationData(hexagon: self, localMask: HTrans.identity)
    }
    
    /**
     The transformation to the base frame of the hexagon at the orthcenter
     - remark:  We're using absolute coordinates, not relative to the pants
     */
    // We initialize to a value that should put the hexagon way off the screen -- this may come back to bite us someday
    var baseMask = HTrans.goForward(20)
    
    /// The color to be used to draw the hexagon, as a guideline
    var color = UIColor.green
    
    /// the lengths of the sides
    var sideLengths = Array<Complex64>(repeating: acosh(2.0 + 0.i), count: 6)
    
    // MARK: - The rotation data
    
    /// the rotation numbers, padded with zeroes for cuffs
    var rotationArray: [Int]
    
    func isCuffIndex(_ i: Int) -> Bool {
        return i % 2 == 0 && rotationArray[i / 2] == 0
    }
    
    func rotationNumberForIndex(_ i: Int) -> Int {
        return rotationArray[i / 2]
    }
    
    // MARK: - The derived geometry of the hexagon

    /// the lengths of the parts from the start to the foot of the altitude
    var firstParts = Array<Complex64>(repeating: Complex64(), count: 6)
    
    /// the lengths of the parts from the foot of the altitude to the end
    var secondParts = Array<Complex64>(repeating: Complex64(), count: 6)
    
    /// the distances from the orthocenter to the feet of the altitude
    var altitudeParts = Array<Double>(repeating: 0.0, count: 6)
    
    /// the transformations from the base frame to the feet of the altitude
    var downFromOrthocenter: [HUVect] = [HUVect](repeating: HTrans.identity, count: 6)
    
    
    var angleToNextAltitude: [Double] = Array<Double>(repeating: 0.0, count: 6)
    
    /// the frames at the feet (pointing outward), rel the base frame
    var foot: [HUVect] = [HUVect](repeating: HTrans.identity, count: 6)
    
    /// the frames at the initial point of each side, pointing forward
    var start: [HUVect] = [HUVect](repeating: HTrans.identity, count: 6)
    
    /// the frames at the feet, pointing forward
    var middle: [HUVect] = [HUVect](repeating: HTrans.identity, count: 6)
    
    /// the frames at the end of the sides, pointing forward
    var end: [HUVect] = [HUVect](repeating: HTrans.identity, count: 6)
    
    /// A point which we hope will aways be in the interior of the hexagon
    var centerpoint: HPoint = HPoint()
    
    // MARK: - The guidelines
    
    /// lines to draw the sides
    var sideGuidelines: [HDrawable] = []
    
    /// lines to draw the altitudes
    var altitudeGuidelines: [HDrawable] = []
    
    /// the hexagon as **HyperbolicPolygon**
    var hexagonGuideline: HDrawable!
    
    /// when set, use **hexagonGuideline** as the guideline
    static var hotPants = true
    
//    var transformedGuidelines: [HDrawable] {
//        if baseMask.distance < 50 {
//           return guidelines.map() {$0.transformedBy(baseMask)}
//        } else {
//            return []
//        }
//     }
    
    var guidelines: [HDrawable] {
        if Hexagon.hotPants {
            return [hexagonGuideline]
        }
        else {
            return sideGuidelines + altitudeGuidelines
        }
    }
    
    var locatedGuidelines: [LocatedObject] {
        return guidelines.map() {LocatedObject(object: $0, location: location)}
    }
    
    // MARK: - The groupoid and its frontier
    var groupoid: [Hexagon:[[EndState]]] = [:]
    
    var groupoidCalculationFrontier =  QueueTable<ForwardState>()
    
    func groupoidTo(_ h: Hexagon, withDistance distance: Int) -> [EndState] {
        var result: [EndState] = []
        for states in groupoid[h]![0...distance] {
            result += states
        }
        return result
    }
    
    func resetGroupoid() { groupoid = [:] }

    // MARK: - Moving to adjacent hexagons
    
    /// The neighbors to the hexagon after the connections are formed
    var neighbor: [HexagonEntry] = Array<HexagonEntry>(repeating: HexagonEntry.placeholder, count: 6)
    
    /// The six forward states that we can arrive at from the given hexagon
    var forwardStates: [ForwardState] {
        var sixArray = [0, 1, 2, 3, 4, 5]
        sixArray = sixArray.filter({$0 % 2 == 1 || isCuffIndex($0)})
        return sixArray.map() { (i: Int) -> ForwardState in
            let entry = neighbor[i]
            var left = 0
            var right = 0
            if i % 2 == 1 {
                left = isCuffIndex((i + 5) % 6) ? 0 : 1
                right = isCuffIndex((i + 1) % 6) ? 0 : 1
            }
            return ForwardState(entry: entry,
                newMotion: entry.motion,
                state: RotationState(left: left, right: right))
        }
    }
    
    /**
     - parameters:
     - old: The old rotationState
     - entrance: The index of the side by which we are entering, in 0..<6
     - exit: The index of the side by which we are exiting, in 0..<6
     - returns: The rotation state in the new hexagon, or nil if this exit is forbidden *for any reason*
     - remark: We assume that the hexagon sides are numbered ***clockwise*** for the purposes of RotationState.left and .right
     */
    func newRotationState(_ old: RotationState, entrance: Int,  exit: Int) -> RotationState? {
        // If the exit index is even, the transition is allowed if there is an actual cuff at this index, and we are not entering from an adjacent side
        if exit % 2 == 0 {
            guard isCuffIndex(exit) else { return nil }
            // Or we could write: if abs((entrance - exit) %% 6 - 3) == 2
            if abs(exit - entrance) == 1 || (exit == 0 && entrance == 5)  {
                return nil
            }
            
            // This is the one other case where we can't go across the cuff, because we've gone across it by right rotation around an index 2 rotation point
            if old.left == 2 && (exit - entrance) %% 6 == 3 &&  rotationNumberForIndex((entrance + 1) % 6) == 2 {
                return nil
            }
            return RotationState.none
        }
        // otherwise we need to examine the type of the two adjacent sides
        let exitPlusOne = (exit + 1) % 6
        let exitMinusOne = (exit + 5) % 6
        // left and right will hold the rotation around the adjancent rotation points
        // each one is zero if the adjacent side is a cuff
        var left = isCuffIndex(exitMinusOne) ? 0 : 1
        var right = isCuffIndex(exitPlusOne) ? 0 : 1
        var special = false
        // Are we rotating to the left around exitMinusOne?
        if (exit - entrance + 6) % 6 == 2 && left > 0 {
            left = old.left + 1
            if left > rotationNumberForIndex(exitMinusOne) {
                return nil
            }
        }
        
        // This is a trick to make sure that we don't collide with the bouncing rightward rotation
        if (exit - entrance) %% 6 == 4 && old.left == rotationNumberForIndex((entrance + 1) % 6) && old.left > 0 {
            left = old.thing ? 3 : 2
        }
        
        // This is another trick to deal with rotation number 2
        if (exit - entrance) %% 6 == 4 && old.left == rotationNumberForIndex((entrance + 1) % 6) - 1 && rotationNumberForIndex(exitMinusOne) == 2 {
            special = true
        }
        if old.thing && (exit - entrance) %% 6 == 2 {
            special = true
        }
        
        
        // Are we rotating to the right around exitPlusOne?
        if (exit - entrance + 6) % 6 == 4 && right > 0 {
            right = old.right + 1
            if right >= rotationNumberForIndex(exitPlusOne) {
                return nil
            }
        }
        return RotationState(left: left, right: right, thing: special)
    }

    
    /**
     - returns: All elements of the groupoid starting at **self** within **cutoffDistance**
     */
    func groupoidForDistance(_ cutoffDistance: Double) -> [EndState] {
        let base = forwardStates
        // For better or for worse, this takes us one step past the cutoffDistance
        let cutoffAbs = distanceToAbs(cutoffDistance)
        let withinRange = {(f: ForwardState) -> Bool in f.newMotion.abs < cutoffAbs}
        var result = fastLeastFixedPoint(base, expand: nextForwardStates, good: withinRange, project: project)
        result.append(EndState(motion: HTrans.identity, hexagon: self))
        return result
    }
    
    func computeInitialGroupoid(timeLimitInMilliseconds: Int, maxDistance: Int) {
        if groupoid.count > 0 {
            return
        }
        var gg: [Hexagon: QueueTable<EndState>] = [self: QueueTable<EndState>()]
        gg[self]!.add(EndState(motion: HTrans.identity, hexagon: self), priority: 0)
        let base = forwardStates
        let priority = {(f: ForwardState) -> Int in
            Int(f.newMotion.distance) }
        let (leftoverForwardStates, newEndStates) = priorityBasedFixedPoint(base: base, expand: nextForwardStates, priority: priority, priorityMax: maxDistance,
                                                                            batchSize: 100, timeLimitInMilliseconds: timeLimitInMilliseconds, project: project)
        groupoidCalculationFrontier = leftoverForwardStates
        while newEndStates.hasNext {
            let p = newEndStates.currentPriority
            let s = newEndStates.getNext!
            let h = s.hexagon
            if let q = gg[h] {
                q.add(s, priority: p)
            } else {
                gg[h] = QueueTable<EndState>()
                gg[h]?.add(s, priority: p)
            }
        }
        for h in gg.keys {
            groupoid[h] = gg[h]?.asArrayOfArrays
        }
    }
    
//    func improveGroupoid(timeLimitInMilliseconds: Int, maxDistance: Int, mask: HyperbolicTransformation)  {
//        let priority = {(f: ForwardState) -> Int in
//            Int(mask.following(f.newMotion).distance)}
//        let newEndStates = priorityBasedFixedPoint(queueTable: groupoidCalculationFrontier, expand: nextForwardStates, priority: priority, priorityMax: maxDistance, batchSize: 100, timeLimitInMilliseconds: timeLimitInMilliseconds, project: project)
//        groupoid += newEndStates
//    }
    
    // MARK: - Initialization and setup
    
    init(alternatingSideLengths: [Complex64]) {
        id = Hexagon.nextId
        Hexagon.nextId += 1
        rotationArray = alternatingSideLengths.map({CuffRotation(complexLength: $0).rotation})
        setAlternatingSideLengths(alternatingSideLengths)
    }
    
    init(alternatingSideLengths: [CuffRotation]) {
        id = Hexagon.nextId
        Hexagon.nextId += 1
        let complexAlternatingSideLengths = alternatingSideLengths.map({$0.complexLength})
        rotationArray = alternatingSideLengths.map({$0.rotation})
        setAlternatingSideLengths(complexAlternatingSideLengths)
    }
    
    func copy() -> Hexagon {
        let alternatingSideLengths = [sideLengths[0], sideLengths[2], sideLengths[4]]
        let h = Hexagon(alternatingSideLengths: alternatingSideLengths)
        h.color = color
        return h
    }
    
    /// (Re)compute the geometry from the alternating side lengths
    /// Should work as a recomputation, when we just change the lengths of the cuffs
    func setAlternatingSideLengths(_ alternatingSideLengths: [Complex64]) {
        for i in 0..<3 {
            sideLengths[2 * i] = alternatingSideLengths[i]
        }
        for i in stride(from: 1, through: 5, by: 2) {
            let (A, B, C) = (sideLengths[(i + 3) %% 6], sideLengths[(i - 1) %% 6], sideLengths[(i + 1) %% 6])
            let num = cosh(B) * cosh(C) + cosh(A)
            let denom = sinh(B) * sinh(C)
            var sideLength = acosh(num/denom)
            if sideLength.re < 0 {
                sideLength = -sideLength
            }
            sideLengths[i] = sideLength
        }
        setUpEverything()
    }
    
    /// Compute all parameters and measurements from the side lengths
    /* This is complicated in the case where the side lengths are complex:
     We want start, middle, foot, and end to be correctly computed when the side in non-degenerate
     They can be junk (I think) when the side is degenerate
     */
    func setUpEverything() {
        for i in 0..<6 {
            firstParts[i] = acoth(cosh(sideLengths[(i - 1) %% 6]) / coth(sideLengths[(i - 2) %% 6]))
            if (firstParts[i].im - Double.PI/2).abs < 0.00001 && sideLengths[i].re.abs > 0.00001 {
                firstParts[i].im = -firstParts[i].im
            }
            secondParts[i] = acoth(cosh(sideLengths[(i + 1) %% 6]) / coth(sideLengths[(i + 2) %% 6]))
            if (secondParts[i].im - Double.PI/2).abs < 0.00001 && sideLengths[i].re.abs > 0.00001 {
                secondParts[i].im = -secondParts[i].im
            }
        }
        // We want to correctly compute altitudeParts and angleToNextAltitude as real numbers in all cases
        for i in 0..<6 {
            altitudeParts[i] = atanh(cosh(firstParts[i]) * tanh(secondParts[(i - 1) %% 6])).re
            // This is redundant because angleToNextAltitude[i + 3] == angleToNextAltitude[i]
            angleToNextAltitude[i] = acos(sinh(secondParts[i]) * sinh(firstParts[(i + 1) % 6])).re
        }
        // Here we're using that downFromOrthocenter[0] is HTrans.identity
        for i in 0..<5 {
            downFromOrthocenter[i + 1] = downFromOrthocenter[i].rotate(angleToNextAltitude[i])
        }
        for i in 0..<6 {
            foot[i] = downFromOrthocenter[i].goForward(altitudeParts[i])
            middle[i] = foot[i].turnLeft
            end[i] = middle[i].goForward(secondParts[i].re)
            start[i] = middle[i].goForward(-firstParts[i].re)
        }
        sideGuidelines = []
        for i in 0..<6 {
            let line = HyperbolicPolyline([start[i].appliedToOrigin, end[i].appliedToOrigin])
            sideGuidelines.append(line)
        }
        altitudeGuidelines = []
        for i in 0..<6 {
            let line = HyperbolicPolyline([HPoint(), foot[i].appliedToOrigin])
            altitudeGuidelines.append(line)
        }
        if let twoIndex = ([0, 1, 2].filter({rotationArray[$0] == 2})).first {
            let opp = (2 * twoIndex + 3) % 6
            centerpoint = downFromOrthocenter[opp].goForward(altitudeParts[opp]/2).appliedToOrigin
        }
        let vertices = [0, 1, 2, 3, 4, 5, 0].map({start[$0].basePoint})
        let h = HyperbolicPolygon(vertices)
        h.useFillColorTable = false
        h.fillColor = color
        hexagonGuideline = h
    }
}

func== (lhs: Hexagon, rhs: Hexagon) -> Bool {
    return lhs === rhs
}
