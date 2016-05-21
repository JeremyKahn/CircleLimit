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
    
    // The half-lengths of the cuffs, which are generally given as the input
    var halfLengths = Array(count: 3, repeatedValue: acosh(2.0)) {
        didSet {
            updateGenerators()
            generateGroup()
        }
    }
    
    // The lengths of the "short orthogeodesics" between pairs of cuffs
    var orthoLengths = Array(count: 3, repeatedValue: acosh(2.0))
    
    // The unit vectors for the start vectors along the cuffs for the central hexagon
    var tMinus = Array(count: 3, repeatedValue: Pants.identity)
    
    // The unit vectors for the end vectors along the cuffs
    var tPlus = Array(count: 3, repeatedValue: Pants.identity)
    
    // The three generators for the pants group
    var generators = Array(count: 3, repeatedValue: Pants.identity)
    
    var generatorsAndInverses: [HTrans] {
        return generators + generators.map({$0.inverse})
    }
    
    var dressedGenerators: [Action] {
        return generators.map() {Action(M: $0)}
    }
    
    // The guidelines for the cuffs and short orthogeodesics
    var cuffGuidelines: [HDrawable] = []
    var orthoGuidelines: [HDrawable] = []
    
    var guidelines: [HDrawable] {
        return cuffGuidelines + orthoGuidelines
    }
    
    // This stores how we're adjacent to the other pants.
    // We should have, for (p, i, s) = adjacencies[j], that p.adjacencies[i] = (self, j, s).
    var adjacenciesAndTwists = Array<(Pants, Int, Double)?>(count: 3, repeatedValue: nil)
    
    var selectedIndex = 0
    
    var keyPoints: [HPoint] {
        let keyPointsWithVectors = tMinus + tPlus
        return keyPointsWithVectors.map() {$0.appliedToOrigin}
    }
    
    var theCenterPointAndRadius: (HPoint, Double) {
        return centerPointAndRadius(keyPoints, delta: 0.1)
    }
    
    var cutoffDistance: Double = absToDistance(0.8)
    
    var radius: Double {
        return theCenterPointAndRadius.1
    }
    
    var adjustedCutoffDistance: Double {
        return cutoffDistance + 3 * radius
    }
    
    var timeToMakeGroup = 0.0
    
    var maxTimeToMakeGroup = 3.0
    
    var group: [HTrans] = []
    
    private var baseGroup = [HTrans()]
    
    var dressedGroup: [Action] {
        return group.map() {Action(M: $0)}
    }
    
    init(halfLengths: [Double]) {
        assert(halfLengths.count == 3)
        self.halfLengths = halfLengths
        updateGenerators()
        generateGroup()
    }

//    func setCuffAtIndex(i: Int, to newLength: Double) {
//        halfLengths[i] = newLength
//        updateGenerators()
//        generateGroup()
//    }
    
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
    
    func generateGroupFromBaseGroup() {
        let startTime = NSDate()
        let (basePointForGeneration, radius) = theCenterPointAndRadius
        let rightMultiplyByGenerators = {
            [basePointForGeneration, radius, cutoffDistance, generatorsAndInverses]
            (M: HTrans) -> [HTrans] in
            let list = generatorsAndInverses.map() {M.following($0)}
            return list.filter() {$0.appliedTo(basePointForGeneration).distanceTo(basePointForGeneration) < cutoffDistance + 3 * radius}
        }
        let nearEnough = { (M0: HTrans, M1: HTrans) -> Bool in M0.nearTo(M1) }
        group = leastFixedPoint(baseGroup, map: rightMultiplyByGenerators, match: nearEnough, maxTime: maxTimeToMakeGroup)
        timeToMakeGroup = secondsSince(startTime)
    }
    
    func generateGroup() {
        baseGroup = [HTrans()]
        generateGroupFromBaseGroup()
    }
    
    func expandGroup() {
        baseGroup = group
        generateGroupFromBaseGroup()
    }
    
}