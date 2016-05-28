//
//  Assembly.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/4/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

struct MatchingVector {
    var P: Pants
    var v: HTrans
    var i: Int
    
    var match: MatchingVector? {
        let temp = P.adjacenciesAndTwists[i]
        guard let (Q, j, twist) = temp else {return nil}
        let w = v.following(HTrans.goForward(twist)).following(HTrans.turnAround)
        return MatchingVector(P: Q, v: w, i: j)
    }
}

class Pants {
    
    // These should probably be class variables, or just class variables of HyperbolicTransformation
    static let identity = HyperbolicTransformation()
    let left = HyperbolicTransformation.turnLeft
    let right = HyperbolicTransformation.turnRight
    
    func updateEverything() {
        updateGenerators()
        generateGroup()
        setUpGeodesicRepresentatives()
        let colors = [UIColor.redColor(),UIColor.greenColor(),UIColor.blueColor(),
                      UIColor.cyanColor(),UIColor.magentaColor(),UIColor.yellowColor()]
        for i in 0..<6 {
            guidelines[i].lineColor = colors[i]
        }
        
    }
    
    init(halfLengths: [Double]) {
        assert(halfLengths.count == 3)
        self.halfLengths = halfLengths
        updateEverything()
    }
    
    // MARK: Parameters and values
    // The half-lengths of the cuffs, which are generally given as the input
    var halfLengths = Array(count: 3, repeatedValue: acosh(2.0)) {
        didSet {
            updateEverything()
        }
    }
    
    // The lengths of the "short orthogeodesics" between pairs of cuffs
    var orthoLengths = Array(count: 3, repeatedValue: acosh(2.0))
    
    // MARK: Marked vectors and generators
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
    

    
    // MARK: Guidelines
    // The guidelines for the cuffs and short orthogeodesics
    var cuffGuidelines: [HDrawable] = []
    var orthoGuidelines: [HDrawable] = []
    
    var guidelines: [HDrawable] {
        return cuffGuidelines + orthoGuidelines
    }
    
    // MARK: Connections to other pants
    // This stores how we're adjacent to the other pants.
    // We should have, for (p, i, s) = adjacencies[j], that p.adjacencies[i] = (self, j, s).
    var adjacenciesAndTwists = Array<(Pants, Int, Double)?>(count: 3, repeatedValue: nil)
    
    var geodesicCutoffDistance: Double = 5
    
     
    static var matchingTolerance = 0.000001
    
    static func match(pants0: Pants, index0: Int, pants1: Pants, index1: Int, twist: Double) {
        assert((pants0.halfLengths[index0] - pants1.halfLengths[index1]).abs < matchingTolerance)
        // YOU SHOULD PROBABLY MAKE THE CUFFS EXACTLY EQUAL IF THEY ARE NOT ALREADY
        pants0.adjacenciesAndTwists[index0] = (pants1, index1, twist)
        pants1.adjacenciesAndTwists[index1] = (pants0, index0, twist)
    }
    
    // MARK: Selected Base Point
    var selectedIndex = 0
    
    var selectedBasePoint: HTrans {
        return tMinus[selectedIndex]
    }
    
    // MARK: Making the group
    var keyPoints: [HPoint] {
        let keyPointsWithVectors = tMinus + tPlus
        return keyPointsWithVectors.map() {$0.appliedToOrigin}
    }
    
    var theCenterPointAndRadius: (HPoint, Double) {
        return centerPointAndRadius(keyPoints, delta: 0.1)
    }
    
    var radius: Double {
        return theCenterPointAndRadius.1
    }
    var cutoffDistance: Double = absToDistance(0.8)
    
    
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
    

//    func setCuffAtIndex(i: Int, to newLength: Double) {
//        halfLengths[i] = newLength
//        updateGenerators()
//        generateGroup()
//    }
    
    var withinRange: HTrans -> Bool {
        return {
            [theCenterPointAndRadius, cutoffDistance]
            (g: HTrans) -> Bool in
            let (basePointForGeneration, radius) = theCenterPointAndRadius
            return g.appliedTo(basePointForGeneration).distanceTo(basePointForGeneration) < cutoffDistance + 3 * radius
        }
    }
    
    func generateGroupFromBaseGroup() {
        let startTime = NSDate()
        let rightMultiplyByGenerators = {
            [withinRange, generatorsAndInverses]
            (M: HTrans) -> [HTrans] in
            let list = generatorsAndInverses.map() {M.following($0)}
            return list.filter(withinRange)
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