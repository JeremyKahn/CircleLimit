//
//  States.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 9/6/16.
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
    
    /// The hexagon that we left
    var oldHexagon: Hexagon? = nil
    
    init() {}
    
    init(entryIndex: Int, motion: HTrans, hexagon: Hexagon) {
        self.entryIndex = entryIndex
        self.motion = motion
        self.hexagon = hexagon
    }
    
    static var placeholder = HexagonEntry()
    
    /// (entryIndex, motion, hexagon?.id)
    var nice: (Int, String, Int?) {
        return (entryIndex, "a: " + motion.a.nice + " lambda: " + motion.lambda.nice, hexagon?.id)
    }
}

struct RotationState {
    
    var left: Int
    var right: Int
    
    var thing = false
    
    init(left: Int, right: Int) {
        self.left = left
        self.right = right
    }
    
    init(left: Int, right: Int, thing: Bool) {
        self.init(left: left, right: right)
        self.thing = thing
    }
    
    static var none: RotationState {
        return RotationState(left: 0, right: 0)
    }
    
    /**
     Returns an array of (side, RotationState) pairs
     - parameters: entrance: The side where we come in
                   hexagon: The hexagon we're in
     */
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
    
    var nice:  (Int, Int?, String, RotationState) {
        return (entry.entryIndex, entry.hexagon?.id, ("a: " + newMotion.a.nice + " lambda: " + newMotion.lambda.nice), state)
    }
    
    init(entry: HexagonEntry, newMotion: HTrans, state: RotationState) {
        self.entry = entry
        self.newMotion = newMotion
        self.state = state
        //        print("Hexagon: \(newMotion)")
    }
    
    var lineToDraw: HDrawable {
        let oldMotion = newMotion.following(entry.motion.inverse)
        let start = oldMotion.appliedTo(entry.oldHexagon!.centerpoint)
        let end = newMotion.appliedTo(entry.hexagon!.centerpoint)
        //        let line = HyperbolicDot(center: end, radius: 0.025)
        let line = HyperbolicPolyline([start, end])
        line.lineColor = UIColor.red
        return line
    }
    
    var endState: EndState {
        return EndState(motion: newMotion, hexagon: entry.hexagon!)
    }
    
    var guidelines: [HDrawable] {
        return [lineToDraw, endState.translatedHexagon]
    }
}

struct EndState {
    var motion: HyperbolicTransformation
    var hexagon: Hexagon
    
    var translatedHexagon: HDrawable {
        return hexagon.hexagonGuideline.transformedBy(motion)
    }
}

/**
 - returns: The forward states that can be reached in one step from **s**
 */
func nextForwardStates(_ s: ForwardState) -> [ForwardState] {
    guard let hexagon = s.entry.hexagon else {return []}
    let exitStates = s.state.exitStates(entrance: s.entry.entryIndex, hexagon: hexagon)
    return exitStates.map() {
        let entry = hexagon.neighbor[$0.0]
        return ForwardState(entry: entry, newMotion: s.newMotion.following(entry.motion), state: $0.1)
    }
}

func project(_ f: ForwardState) -> EndState {
    return f.endState
}

func groupFromEndStates(_ endStates: [EndState], for baseHexagon: Hexagon) -> [HTrans] {
    return endStates.filter({$0.hexagon === baseHexagon}).map({$0.motion})
}
