//
//  Assembly.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/4/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

class Pants {
    
    // These should probably be class variables, or just class variables of HyperbolicTransformation
    static let identity = HyperbolicTransformation()
    let left = HyperbolicTransformation.turnLeft
    let right = HyperbolicTransformation.turnRight
    
    var halfLengths = Array(count: 3, repeatedValue: acosh(2.0))
    
    var orthoLengths = Array(count: 3, repeatedValue: acosh(2.0))
    
    var tMinus = Array(count: 3, repeatedValue: Pants.identity)
    
    var tPlus = Array(count: 3, repeatedValue: Pants.identity)
    
    var generators = Array(count: 3, repeatedValue: Pants.identity)
    
    var dressedGenerators: [Action] {
        return generators.map() {Action(M: $0)}
    }
    
    var cuffGuidelines: [HDrawable] = []
    var orthoGuidelines: [HDrawable] = []
    
    var guidelines: [HDrawable] {
        return cuffGuidelines + orthoGuidelines
    }
    
    var adjacencies = Array<(Pants, Int)?>(count: 3, repeatedValue: nil)
    
    init(halfLengths: [Double]) {
        assert(halfLengths.count == 3)
        self.halfLengths = halfLengths
        updateGenerators()
    }

    func setCuffAtIndex(i: Int, to newLength: Double) {
        halfLengths[i] = newLength
        updateGenerators()
    }
    
    func updateGenerators() {
        for i in 0..<3 {
            orthoLengths[i] = sideInRightAngledHexagonWithOpposite(halfLengths[i], andAdj: halfLengths[(i+1) % 3], andAdj: halfLengths[(i + 2) % 3])
        }
        for i in 0..<3 {
            tPlus[i] = tMinus[i].following(HyperbolicTransformation.goForward(halfLengths[i]))
            tMinus[(i+1)%3] = tPlus[i].following(left).following(HyperbolicTransformation.goForward(orthoLengths[(i+2)%3])).following(left)

        }
        for i in 0..<3 {
            generators[i] = tMinus[i].following(HyperbolicTransformation.goForward(2 * halfLengths[i])).following(tMinus[i].inverse)
        }
        cuffGuidelines = []
        for i in 0..<3 {
            cuffGuidelines.append(HyperbolicPolyline([tMinus[i].appliedToOrigin, generators[i].following(tMinus[i]).appliedToOrigin]))
        }
        orthoGuidelines = []
        for i in 0..<3 {
            orthoGuidelines.append(HyperbolicPolyline([tPlus[(i+1)%3].appliedToOrigin, tMinus[(i+2)%3].appliedToOrigin]))
        }
    }
    
    
}