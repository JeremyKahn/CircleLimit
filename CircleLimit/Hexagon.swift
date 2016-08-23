//
//  Hexagon.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

/** An entry into an adjacent hexagon (from a given one).
    Computed from the geometric graph and used to compute the groupoid
 */
struct HexagonEntry {
    
    /// The index of the side where we will enter
    var entryIndex: Int = 0
    
    /// The motion from base frame of the present hexagon to the new one
    var motion: HyperbolicTransformation = HTrans.identity
    
    /// The hexagon we will enter
    var hexagon: Hexagon? = nil
    
    init() {}
    
    init(entryIndex: Int, motion: HTrans, hexagon: Hexagon) {
        self.entryIndex = entryIndex
        self.motion = motion
        self.hexagon = hexagon
    }
    
    static var placeholder = HexagonEntry()
    
    var readable: (Int, HTrans, Int) {
        return (entryIndex, motion, hexagon!.id)
    }
}

struct RotationState {
    
    var left: Int
    var right: Int
    
    static var none: RotationState {
        return RotationState(left: 0, right: 0)
    }
    
    func exitStates(entrance i: Int, hexagon h: Hexagon) -> [(Int, RotationState)] {
        let possibleSides = [i + 1, i + 2, i + 3, i + 4, i + 5].map({$0 % 6})
        let resultsQ = possibleSides.map() { (j: Int) -> (Int, RotationState?) in
            return (j, h.newRotationState(self, entrance: i, exit: j))
        }
        let results = resultsQ.filter({$0.1 != nil}).map() {
            (j: Int, s: RotationState?) -> (Int, RotationState) in
            return (j, s!)
        }
        return results
    }
}






/// The entry to the new hexagon, the motion to the new hexagon, and the state in the new hexagon
struct ForwardState {
    var entry: HexagonEntry
    var newMotion: HTrans
    var state: RotationState
}

struct EndState {
    var motion: HyperbolicTransformation
    var hexagon: Hexagon
}

/**
 - returns: The forward states that can be reached in one step from **s**
 */
func nextForwardStates(s: ForwardState) -> [ForwardState] {
    guard let hexagon = s.entry.hexagon else {return []}
    let exitStates = s.state.exitStates(entrance: s.entry.entryIndex, hexagon: hexagon)
    return exitStates.map() {
        let entry = hexagon.neighbor[$0.0]
        return ForwardState(entry: entry, newMotion: s.newMotion.following(entry.motion), state: $0.1)
    }
}

func project(f: ForwardState) -> EndState {
    return EndState(motion: f.newMotion, hexagon: f.entry.hexagon!)
}

func groupFromEndStates(endStates: [EndState], for baseHexagon: Hexagon) -> [HTrans] {
    return endStates.filter({$0.hexagon === baseHexagon}).map({$0.motion})
}


/// A right angled hexagon in the hyperbolic plane
class Hexagon {
    
    static var nextId = 0
    
    var id: Int
    
    /// The transformation to the base frame of the hexagon at the orthcenter
    var baseMask = HTrans()
    
    /// The color to be used to draw the hexagon, as a guideline
    var color = UIColor.purpleColor()
    
    /// the lengths fo the sides
    var sideLengths: [Double] = Array<Double>(count: 6, repeatedValue: acosh(2.0))
    
    /// the rotation numbers, padded with zeroes for cuffs
    var rotationArray: [Int] {
        return [0, 0, 0]
    }
    
    func isCuffIndex(i: Int) -> Bool {
        return rotationArray[i / 2] == 0
    }
    
    func rotationNumberForIndex(i: Int) -> Int {
        return rotationArray[i / 2]
    }
    
    /**
     - parameters:
        - old: The old rotationState
        - side: The side by which we are exiting
     - returns: The rotation state in the new hexagon, or nil if this exit is forbidden *for any reason*
     - remark: We assume that the hexagon sides are numbered ***clockwise*** for the purposes of RotationState.left and .right
     */
    func newRotationState(old: RotationState, entrance: Int,  exit: Int) -> RotationState? {
        if exit % 2 == 0 {
            if abs(exit - entrance) == 1 {
                return nil
            }
            return isCuffIndex(exit) ? RotationState.none : nil
        }
        let exitPlusOne = (exit + 1) % 6
        let exitMinusOne = (exit + 5) % 6
        var left = isCuffIndex(exitMinusOne) ? 0 : 1
        var right = isCuffIndex(exitPlusOne) ? 0 : 1
        if (exit - entrance + 6) % 6 == 2 && !isCuffIndex(exitPlusOne) {
            left = old.left + 1
            if left > rotationNumberForIndex(exitPlusOne) {
                return nil
            }
        }
        if (exit - entrance + 6) % 6 == 4 && !isCuffIndex(exitMinusOne) {
            right = old.right + 1
            if right > rotationNumberForIndex(exitMinusOne) {
                return nil
            }
        }
        return RotationState(left: left, right: right)
    }
    
    
    /// the lengths of the parts from the start to the foot of the altitude
    var firstParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    /// the lengths of the parts from the foot of the altitude to the end
    var secondParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    /// the distances from the orthocenter to the feet of the altitude
    var altitudeParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    /// the transformations from the base frame to the feet of the altitude
    var downFromOrthocenter: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    
    var angleToNextAltitude: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    /// the frames at the feet (pointing outward), rel the base frame
    var foot: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    /// the frames at the initial point of each side, pointing forward
    var start: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    /// the frames at the feet, pointing forward
    var middle: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    /// the frames at the end of the sides, pointing forward
    var end: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    /// lines to draw the sides
    var sideGuidelines: [HDrawable] = []
    
    /// lines to draw the altitudes
    var altitudeGuidelines: [HDrawable] = []
    
    /// the hexagon as **HyperbolicPolygon**
    var hexagonGuideline: HDrawable!
    
    /// when set, use **hexagonGuideline** as the guideline
    static var hotPants = true
    
    var guidelines: [HDrawable] {
        if Hexagon.hotPants {
            return [hexagonGuideline]
        }
        else {
            return sideGuidelines + altitudeGuidelines
        }
    }
    
    /// The neighbors to the hexagon after the connections are formed
    var neighbor: [HexagonEntry] = Array<HexagonEntry>(count: 6, repeatedValue: HexagonEntry.placeholder)
    
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
    
    init(alternatingSideLengths: [Double]) {
        id = Hexagon.nextId
        Hexagon.nextId += 1
        setAlternatingSideLengths(alternatingSideLengths)
    }
    
    /// (Re)compute the geometry from the alternating side lengths
    func setAlternatingSideLengths(alternatingSideLengths: [Double]) {
        for i in 0..<3 {
            sideLengths[2 * i] = alternatingSideLengths[i]
        }
        for i in 1.stride(through: 5, by: 2) {
            let (A, B, C) = (sideLengths[(i + 3) %% 6], sideLengths[(i - 1) %% 6], sideLengths[(i + 1) %% 6])
            let num = cosh(B) * cosh(C) + cosh(A)
            let denom = sinh(B) * sinh(C)
            sideLengths[i] = acosh(num/denom)
        }
        setUpEverything()
    }
    
    /**
     - returns: All elements of the groupoid starting at **self** within **cutoffDistance**
     */
    func allMorphisms(cutoffDistance: Double) -> [EndState] {
        let base = forwardStates
        // For better or for worse, this takes us one step past the cutoffDistance
        let cutoffAbs = distanceToAbs(cutoffDistance)
        let withinRange = {(f: ForwardState) -> Bool in f.newMotion.abs < cutoffAbs}
        var result = fastLeastFixedPoint(base, expand: nextForwardStates, good: withinRange, project: project)
        result.append(EndState(motion: HTrans.identity, hexagon: self))
        return result
    }
    
    func copy() -> Hexagon {
        let alternatingSideLengths = [sideLengths[0], sideLengths[2], sideLengths[4]]
        let h = Hexagon(alternatingSideLengths: alternatingSideLengths)
        h.color = color
        return h
    }
    
    /// Compute all parameters and measurements from the side lengths
    func setUpEverything() {
        for i in 0..<6 {
            firstParts[i] = acoth(cosh(sideLengths[(i - 1) %% 6]) / coth(sideLengths[(i - 2) %% 6]))
            secondParts[i] = acoth(cosh(sideLengths[(i + 1) %% 6]) / coth(sideLengths[(i + 2) %% 6]))
        }
        for i in 0..<6 {
            altitudeParts[i] = atanh(cosh(firstParts[i]) * tanh(secondParts[(i - 1) %% 6]))
            // This is redundant because angleToNextAltitude[i + 3] == angleToNextAltitude[i]
            angleToNextAltitude[i] = acos(sinh(secondParts[i]) * sinh(firstParts[(i + 1) % 6]))
        }
        // Here we're using that downFromOrthocenter[0] is HTrans.identity
        for i in 0..<5 {
            downFromOrthocenter[i + 1] = downFromOrthocenter[i].rotate(angleToNextAltitude[i])
        }
        for i in 0..<6 {
            foot[i] = downFromOrthocenter[i].goForward(altitudeParts[i])
            middle[i] = foot[i].turnLeft
            end[i] = middle[i].goForward(secondParts[i])
            start[i] = middle[i].goForward(-firstParts[i])
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
        
        let vertices = [0, 1, 2, 3, 4, 5, 0].map({start[$0].basePoint})
        let h = HyperbolicPolygon(vertices)
        h.useFillColorTable = false
        h.fillColor = color
        hexagonGuideline = h
    }
}