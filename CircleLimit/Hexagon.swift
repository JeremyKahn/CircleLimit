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

/// The possible states we can be in upon entering a hexagon
enum HexState {
    /// We've entered from within a pants, and can only go to the opposite side and its neighbors
    case three
    /// We've entered from another pants, and can exit by any other side
    case five

    /**
     - returns: An array of (side, state) tuples that are the possible exit sides and states
     - parameter entrance: The index of the side where we are entering
     */
    func exitStates(entrance i: Int) -> [(i: Int, state: HexState)] {
        let fiveArray = [1, 2, 3, 4, 5]
        // three five three five three
        let fiveStuff = fiveArray.map({($0, $0 % 2 == 0 ? HexState.five : HexState.three)})
        switch self {
        case three:
            return [((i+2) % 6, three), ((i+3) % 6, five), ((i+4) % 6, three)]
        case five:
            return fiveStuff.map() {
                (($0.0 + i) % 6, $0.1)
            }
        }
    }
}

/// The entry to the new hexagon, the motion to the new hexagon, and the state in the new hexagon
struct ForwardState {
    var entry: HexagonEntry
    var newMotion: HTrans
    var state: HexState
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
    let exitStates = s.state.exitStates(entrance: s.entry.entryIndex)
    return exitStates.map() {
        let entry = hexagon.neighbor[$0.i]
        return ForwardState(entry: entry, newMotion: s.newMotion.following(entry.motion), state: $0.state)
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
        let sixArray = [0, 1, 2, 3, 4, 5]
        return sixArray.map() { (i: Int) -> ForwardState in
            let entry = neighbor[i]
            return ForwardState(entry: entry,
                newMotion: entry.motion,
                state: i % 2 == 0 ? .five : .three)
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