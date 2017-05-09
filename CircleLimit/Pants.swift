//
//  Pants.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit


func weightedColor(_ weights: [CGFloat], colors: [UIColor]) -> UIColor {
    let n = min(weights.count, colors.count)
    var red: CGFloat = 0
    var blue: CGFloat = 0
    var green: CGFloat = 0
    var alpha: CGFloat = 1
    var red2: CGFloat = 0
    var blue2: CGFloat = 0
    var green2: CGFloat = 0
    
    for i in 0..<n {
        colors[i].getRed(&red, green: &green, blue: &blue, alpha:&alpha)
        let w = weights[i]
        red2 += w * red
        green2 += w * green
        blue2 += w * blue
    }
    return UIColor(red: red2, green: green2, blue: blue2, alpha: alpha)
}


class Pants {
    
    var baseMask: HTrans {
        return hexagons[0].baseMask
    }
    
    var cuffHalfLengths: [Complex64] {
        didSet {
            hexagons[0].setAlternatingSideLengths(cuffHalfLengths)
            hexagons[1].setAlternatingSideLengths(cuffHalfLengths.reversed())
            updateSelfAndNeighbors()
        }
    }
    
    var hexagons: [Hexagon]
    
    var color = UIColor.clear {
        didSet {
            hexagons[0].color = color
            hexagons[1].color = weightedColor([0.7, 0.3], colors: [color, UIColor.gray])
            for h in hexagons {
                h.hexagonGuideline.fillColor = h.color
            }
        }
    }
    
    var localGroupoidGenerators: [GroupoidElement] = []
    
    var groupoidEltsToAdjacentPants: [GroupoidElement?] = [GroupoidElement?](repeating: nil, count: 3)
    
    var definedGroupoidEltsToAdjacentPants: [GroupoidElement] {
        var result: [GroupoidElement] = []
        for e in groupoidEltsToAdjacentPants {
            if let elt = e {
                result.append(elt)
            }
        }
        return result
    }
    
    var groupoidGenerators: [GroupoidElement] {
        return localGroupoidGenerators + definedGroupoidEltsToAdjacentPants
    }
    
    var adjacenciesAndTwists = Array<(Pants, Int, Double)?>(repeating: nil, count: 3)
    
    var id: Int
    
    var guidelines: [LocatedObject] {
        return hexagonGuidelines
//        return orthoGuidelines
        
    }
    
    static var firstHexagonOnly = false
    
    // This would actually be more readable as a nested for loop, with append
    var hexagonGuidelines: [LocatedObject] {
        if Pants.firstHexagonOnly {
            return hexagons[0].locatedGuidelines
        }
        return hexagons.flatMap({$0.locatedGuidelines})
    }
    
    /// An array of size three, with a guideline for each actual cuff, and nil at rotation indices
    var cuffGuidelines: [LocatedObject?] = Array(repeating: nil, count: 3)
    
    var orthoGuidelines: [LocatedObject] = []
    
    static var nextId = 0
    
    init(cuffHalfLengths: [Complex64]) {
        id = Pants.nextId
        Pants.nextId += 1
        self.cuffHalfLengths = cuffHalfLengths
        hexagons = [Hexagon(alternatingSideLengths: cuffHalfLengths),
                    Hexagon(alternatingSideLengths: cuffHalfLengths.reversed())]
        setUpGuidelines()
        setUpLocalGroupoid()
    }
    
    convenience init(cuffHalfLengths: [Double]) {
        self.init(cuffHalfLengths: cuffHalfLengths.map({$0 + 0.i}))
    }
    
    convenience init(cuffHalfLengths: [CuffRotation]) {
        let complexLengths = cuffHalfLengths.map({$0.complexLength})
//        if complexLengths[0].re == 0 && complexLengths[1].re == 0 && complexLengths[2].im == 0 {
//            print("Hello, Jeremy!")
////            complexLengths[0] = Double.PI.i - complexLengths[0]
//        }
        self.init(cuffHalfLengths: complexLengths)
    }
    
    func setUpGuidelines() {
        orthoGuidelines = []
        for i in 0...2 {
            let sideIndex = sideIndexForCuffIndex(i, AndHexagonIndex: 0)
            let walker = hexagons[0].start[sideIndex]
            let firstPoint = walker.appliedToOrigin
            let oppositePoint = hexagons[0].start[(sideIndex - 1) %% 6].appliedToOrigin
            let orthoGuideline = HyperbolicPolyline([firstPoint, oppositePoint])
            orthoGuideline.lineColor = UIColor.gray
            orthoGuidelines.append(LocatedObject(object: orthoGuideline, location: hexagons[0].location))
            if hexagons[0].isCuffIndex(sideIndex) {
                let secondPoint = walker.goForward(cuffHalfLengths[i].re * 2).appliedToOrigin
                cuffGuidelines[i] = LocatedObject(object: HyperbolicPolyline([firstPoint, secondPoint]),
                                                  location: hexagons[0].location)
            }
        }
    }
    
    func setUpLocalGroupoid() {
        for i in 0...1 {
            let start = hexagons[i]
            let end = hexagons[1-i]
            for j in stride(from: 1, through: 5, by: 2) {
                let k = (10 - j) % 6
                let instruction = start.start[j].turnAround.following((end.end[k]).inverse)
                
                // This is the old and deprecated way of setting up
                let g = GroupoidElement(M: instruction, start: start, end: end)
                localGroupoidGenerators.append(g)
                
                // This is the new one
                var e = HexagonEntry(entryIndex: k, motion: instruction, hexagon: end)
                e.oldHexagon = start
                start.neighbor[j] = e
            }
        }
    }
    
    /**
     - returns: The side index of hexagons[**hexagonIndex**] for cuff **cuffIndex**
     */
    func sideIndexForCuffIndex(_ cuffIndex: Int, AndHexagonIndex hexagonIndex: Int) -> Int {
        return hexagonIndex == 0 ? 2 * cuffIndex : 4 - 2 * cuffIndex
    }
    
    // TODO: Reduce the twist by 2 * cuffLength
    // TODO: Reduce the twist further by switching hexagon, if need be
    func setUpGroupoidElementsToAdjacentPants() {
        for k in 0...2 {
            setUpGroupoidElementToAdjacentPantsForIndex(k, updateNeighbor: false)
        }
    }
    
    func updateSelfAndNeighbors() {
        setUpGuidelines()
        setUpLocalGroupoid()
        for k in 0...2 {
            setUpGroupoidElementToAdjacentPantsForIndex(k, updateNeighbor: true)
        }
    }
    
    // Here we're assuming that cuffHalfLength[k] is real
    func setUpGroupoidElementToAdjacentPantsForIndex(_ k: Int, updateNeighbor: Bool) {
        guard let (adjPants, neighborCuffIndex, twist) = adjacenciesAndTwists[k] else {return}
        let halfLength = cuffHalfLengths[k].re
        let wholeLength = 2 * halfLength
        var reducedTwist = twist %% (wholeLength)
        reducedTwist = reducedTwist > halfLength ? reducedTwist - wholeLength : reducedTwist
        assert(reducedTwist.abs <= halfLength)
        for i in 0...1 {
            let selfHexagon = hexagons[i]
            let selfSideIndex = sideIndexForCuffIndex(k, AndHexagonIndex: i)
            let selfVector = selfHexagon.start[selfSideIndex]
            
            let neighborHexagon = adjPants.hexagons[i]
            let neighborSideIndex = sideIndexForCuffIndex(neighborCuffIndex, AndHexagonIndex: i)
            let neighborVector = adjPants.hexagons[i].end[neighborSideIndex]
            
            let instruction = selfVector.goForward(reducedTwist).turnAround.following(neighborVector.inverse)
            
            // The old and deprecated way
            let g = GroupoidElement(M: instruction, start: selfHexagon, end: neighborHexagon)
            groupoidEltsToAdjacentPants[k] = g
            
            // The new and cooler way
            var e = HexagonEntry(entryIndex: neighborSideIndex, motion: instruction, hexagon: neighborHexagon)
            e.oldHexagon = selfHexagon
            selfHexagon.neighbor[selfSideIndex] = e
            
            if updateNeighbor {
                var eN = HexagonEntry(entryIndex: selfSideIndex, motion: instruction.inverse, hexagon: selfHexagon)
                eN.oldHexagon = neighborHexagon
                neighborHexagon.neighbor[neighborSideIndex] = eN
            }
        }
    }
    
    
}
