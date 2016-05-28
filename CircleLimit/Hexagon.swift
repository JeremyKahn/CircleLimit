//
//  Hexagon.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation


struct HexagonEntry {
    
    var entryIndex: Int
    var motion: HyperbolicTransformation
    weak var hexagon: Hexagon?
    
    static var placeholder = HexagonEntry(entryIndex: 0, motion: HTrans.identity, hexagon: nil)
}

enum HexState {
    case three, five
    
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

// the entry to the new hexagon, the old motion to the old hexagon, and the state in the new hexagon
struct ForwardState {
    var entry: HexagonEntry
    var newMotion: HTrans
    var state: HexState
}

struct EndState {
    var motion: HyperbolicTransformation
    var hexagon: Hexagon
}

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

class Hexagon {
    
    var baseMask = HTrans()
    
    var sideLengths: [Double] = Array<Double>(count: 6, repeatedValue: acosh(2.0))
    
    var firstParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var secondParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var altitudeParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var downFromOrthocenter: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var angleToNextAltitude: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var foot: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var start: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var middle: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var end: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)

    var sideGuidelines: [HDrawable] = []
    
    var altitudeGuidelines: [HDrawable] = []
    
    var guidelines: [HDrawable] {
        return sideGuidelines + altitudeGuidelines
    }
    
    var neighbor: [HexagonEntry] = Array<HexagonEntry>(count: 6, repeatedValue: HexagonEntry.placeholder)
    
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
    
    func allMorphisms(cutoffDistance: Double) -> [EndState] {
        let base = forwardStates
        // For better or for worse, this takes as one step past the cutoffDistance
        let cutoffAbs = distanceToAbs(cutoffDistance)
        let withinRange = {(f: ForwardState) -> Bool in f.newMotion.abs < cutoffAbs}
        var result = fastLeastFixedPoint(base, expand: nextForwardStates, good: withinRange, project: project)
        result.append(EndState(motion: HTrans.identity, hexagon: self))
        return result
    }
    
    func copy() -> Hexagon {
        let alternatingSideLengths = [sideLengths[0], sideLengths[2], sideLengths[4]]
        return Hexagon(alternatingSideLengths: alternatingSideLengths)
    }
    
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
    }
    
}