//
//  Pants.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit


func weightedColor(weights: [CGFloat], colors: [UIColor]) -> UIColor {
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
            hexagons[1].setAlternatingSideLengths(cuffHalfLengths.reverse())
            updateSelfAndNeighbors()
        }
    }
    
    var hexagons: [Hexagon]
    
    var color = UIColor.clearColor()
    
    var localGroupoidGenerators: [GroupoidElement] = []
    
    var groupoidEltsToAdjacentPants: [GroupoidElement?] = [GroupoidElement?](count: 3, repeatedValue: nil)
    
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
    
    var adjacenciesAndTwists = Array<(Pants, Int, Double)?>(count: 3, repeatedValue: nil)
    
    var id: Int
    
    var transformedGuidelines: [HDrawable] {
        return guidelines.map({$0.transformedBy(baseMask)})
    }
    
    var guidelines: [HDrawable] {
        return hexagonGuidelines
//        return orthoGuidelines
        
    }
    
    static var firstHexagonOnly = true
    
    // This would actually be more readable as a nested for loop, with append
    var hexagonGuidelines: [HDrawable] {
        if Pants.firstHexagonOnly {
            let h = hexagons[0]
            return h.guidelines.map({$0.transformedBy(baseMask.following(h.baseMask))})
        }
        let nestedArray = hexagons.map() {
            (h: Hexagon) -> [HDrawable] in
            h.guidelines.map({$0.transformedBy(baseMask.following(h.baseMask))})
        }
        return nestedArray.flatten().map({$0})
    }
    
    func setColor(color: UIColor) {
        self.color = color
        hexagons[0].color = color
        hexagons[1].color = weightedColor([0.5, 0.5], colors: [color, UIColor.grayColor()])
        for h in hexagons {
            h.hexagonGuideline.fillColor = h.color
        }
    }
    
    /// An array of size three, with a guideline for each actual cuff, and nil at rotation indices
    var cuffGuidelines: [HDrawable?] = Array(count: 3, repeatedValue: nil)
    
    var orthoGuidelines: [HDrawable] = []
    
    static var nextId = 0
    
    init(cuffHalfLengths: [Complex64]) {
        id = Pants.nextId
        Pants.nextId += 1
        self.cuffHalfLengths = cuffHalfLengths
        hexagons = [Hexagon(alternatingSideLengths: cuffHalfLengths),
                    Hexagon(alternatingSideLengths: cuffHalfLengths.reverse())]
        setUpGuidelines()
        setUpLocalGroupoid()
    }
    
    convenience init(cuffHalfLengths: [Double]) {
        self.init(cuffHalfLengths: cuffHalfLengths.map({$0 + 0.i}))
    }
    
    convenience init(cuffHalfLengths: [CuffRotation]) {
        var complexLengths = cuffHalfLengths.map({$0.complexLength})
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
            orthoGuideline.lineColor = UIColor.grayColor()
            orthoGuidelines.append(orthoGuideline)
            if hexagons[0].isCuffIndex(sideIndex) {
                let secondPoint = walker.goForward(cuffHalfLengths[i].re * 2).appliedToOrigin
                cuffGuidelines[i] = HyperbolicPolyline([firstPoint, secondPoint])
            }
        }
    }
    
    func setUpLocalGroupoid() {
        for i in 0...1 {
            let start = hexagons[i]
            let end = hexagons[1-i]
            for j in 1.stride(through: 5, by: 2) {
                let k = (10 - j) % 6
                let instruction = start.start[j].turnAround.following((end.end[k]).inverse)
                
                // This is the old and deprecated way of setting up
                let g = GroupoidElement(M: instruction, start: start, end: end)
                localGroupoidGenerators.append(g)
                
                // This is the new one
                let e = HexagonEntry(entryIndex: k, motion: instruction, hexagon: end)
                start.neighbor[j] = e
            }
        }
    }
    
    /**
     - returns: The side index of hexagons[**hexagonIndex**] for cuff **cuffIndex**
     */
    func sideIndexForCuffIndex(cuffIndex: Int, AndHexagonIndex hexagonIndex: Int) -> Int {
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
    func setUpGroupoidElementToAdjacentPantsForIndex(k: Int, updateNeighbor: Bool) {
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
            let e = HexagonEntry(entryIndex: neighborSideIndex, motion: instruction, hexagon: neighborHexagon)
            selfHexagon.neighbor[selfSideIndex] = e
            
            if updateNeighbor {
                let eN = HexagonEntry(entryIndex: selfSideIndex, motion: instruction.inverse, hexagon: selfHexagon)
                neighborHexagon.neighbor[neighborSideIndex] = eN
            }
        }
    }
    
    
}