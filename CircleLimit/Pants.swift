//
//  Pants.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

class Pants {
    
    var baseMask: HTrans {
        return hexagons[0].baseMask
    }
    
    var cuffHalfLengths: [Double] {
        didSet {
            setUpEverything()
        }
    }
    
    var hexagons: [Hexagon]
    
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
        return orthoGuidelines
    }
    
    var hexagonGuidelines: [HDrawable] {
        return [HDrawable](hexagons.map({$0.altitudeGuidelines}).flatten())
    }
    
    var cuffGuidelines: [HDrawable] = []
    
    var orthoGuidelines: [HDrawable] = []
    
    static var nextId = 0
    
    init(cuffHalfLengths: [Double]) {
        id = Pants.nextId++
        self.cuffHalfLengths = cuffHalfLengths
        hexagons = [Hexagon(alternatingSideLengths: cuffHalfLengths),
                    Hexagon(alternatingSideLengths: [Double](cuffHalfLengths.reverse()))]
        setUpGuidelines()
        setUpLocalGroupoid()
    }
    
    func setUpEverything() {
        setUpHexagons()
        setUpLocalGroupoid()
        setUpGroupoidElementsToAdjacentPants()
        setUpGuidelines()
    }
    
    func setUpHexagons() {
        hexagons = [Hexagon(alternatingSideLengths: cuffHalfLengths),
                    Hexagon(alternatingSideLengths: [Double](cuffHalfLengths.reverse()))]
    }
    
    
    func setUpGuidelines() {
        cuffGuidelines = []
        orthoGuidelines = []
        for i in 0...2 {
            let sideIndex = sideIndexForCuffIndex(i, AndHexagonIndex: 0)
            let walker = hexagons[0].start[sideIndex]
            let firstPoint = walker.appliedToOrigin
            let secondPoint = walker.goForward(cuffHalfLengths[i] * 2).appliedToOrigin
            cuffGuidelines.append(HyperbolicPolyline([firstPoint, secondPoint]))
            let oppositePoint = hexagons[0].start[(sideIndex - 1) %% 6].appliedToOrigin
            let orthoGuideline = HyperbolicPolyline([firstPoint, oppositePoint])
            orthoGuideline.lineColor = UIColor.blueColor()
            orthoGuidelines.append(orthoGuideline)
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
    
    func sideIndexForCuffIndex(cuffIndex: Int, AndHexagonIndex hexagonIndex: Int) -> Int {
        return hexagonIndex == 0 ? 2 * cuffIndex : 4 - 2 * cuffIndex
    }
    
    // TODO: Reduce the twist by 2 * cuffLength
    // TODO: Reduce the twist further by switching hexagon, if need be
    func setUpGroupoidElementsToAdjacentPants() {
        for k in 0...2 {
            setUpGroupoidElementToAdjacentPantsForIndex(k)
        }
    }
    
    // Right now we'll do it the simple way rather than the cool wa
    func setUpGroupoidElementToAdjacentPantsForIndex(k: Int) {
        guard let (adjPants, neighborCuffIndex, twist) = adjacenciesAndTwists[k] else {return}
        let halfLength = cuffHalfLengths[k]
        let wholeLength = 2 * halfLength
        var reducedTwist = twist %% (wholeLength)
        reducedTwist = reducedTwist > halfLength ? reducedTwist - wholeLength : reducedTwist
        for i in 0...1 {
            let selfHexagon = hexagons[i]
            let selfIndex = sideIndexForCuffIndex(k, AndHexagonIndex: i)
            let selfVector = selfHexagon.start[selfIndex]
            
            let neighborHexagon = adjPants.hexagons[i]
            let neighborSideIndex = sideIndexForCuffIndex(neighborCuffIndex, AndHexagonIndex: i)
            let neighborVector = adjPants.hexagons[i].end[neighborSideIndex]
            let instruction = selfVector.goForward(twist).turnAround.following(neighborVector.inverse)
            
            // The old and deprecated way
            let g = GroupoidElement(M: instruction, start: selfHexagon, end: neighborHexagon)
            groupoidEltsToAdjacentPants[k] = g
            
            // The new and cooler way
            let e = HexagonEntry(entryIndex: neighborSideIndex, motion: instruction, hexagon: neighborHexagon)
            selfHexagon.neighbor[selfIndex] = e
        }
    }
    
    
}