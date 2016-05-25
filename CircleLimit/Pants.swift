//
//  Pants.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

class Pants {
    
    var cuffHalfLengths: [Double] {
        didSet {
            setUpEverything()
        }
    }
    
    var hexagons: [Hexagon]
    
    var localGroupoidGenerators: [GroupoidElement] = []
    
    var groupoidEltsToAdjacentPants: [GroupoidElement] = []
    
    var groupoidGenerators: [GroupoidElement] {
        return localGroupoidGenerators + groupoidEltsToAdjacentPants
    }
    
    var adjacenciesAndTwists = Array<(Pants, Int, Double)?>(count: 3, repeatedValue: nil)
    
    init(cuffHalfLengths: [Double]) {
        self.cuffHalfLengths = cuffHalfLengths
        hexagons = [Hexagon(alternatingSideLengths: cuffHalfLengths),
                    Hexagon(alternatingSideLengths: [Double](cuffHalfLengths.reverse()))]
        setUpLocalGroupoid()
    }
    
    func setUpHexagons() {
        hexagons = [Hexagon(alternatingSideLengths: cuffHalfLengths),
                    Hexagon(alternatingSideLengths: [Double](cuffHalfLengths.reverse()))]
    }
    
    func setUpEverything() {
        setUpHexagons()
        setUpLocalGroupoid()
        setUpGroupoidElementsToAdjacentPants()
    }
    
    func setUpLocalGroupoid() {
        for i in 0...1 {
            for j in 1.stride(through: 5, by: 2) {
                let k = (10 - j) % 6
                let instruction = hexagons[i].start[j].turnAround.following((hexagons[1-i].end[k]).inverse)
                let g = GroupoidElement(M: instruction, start: hexagons[i], end: hexagons[1 - i])
                localGroupoidGenerators.append(g)
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
            guard let (adjPants, neighborCuffIndex, twist) = adjacenciesAndTwists[k] else {continue}
            let cuffLength = 2 * cuffHalfLengths[k]
            var reducedTwist = twist %% (cuffLength)
            reducedTwist = reducedTwist > cuffLength ? reducedTwist - 2 * cuffLength : reducedTwist
            for i in 0...1 {
                let selfIndex = sideIndexForCuffIndex(k, AndHexagonIndex: i)
                let selfVector = hexagons[i].start[selfIndex]
                let neighborSideIndex = sideIndexForCuffIndex(neighborCuffIndex, AndHexagonIndex: i)
                let neighborVector = adjPants.hexagons[i].end[neighborSideIndex]
                let instruction = selfVector.goForward(twist).turnAround.following(neighborVector.inverse)
                let g = GroupoidElement(M: instruction, start: hexagons[i], end: adjPants.hexagons[i])
                groupoidEltsToAdjacentPants.append(g)
            }
        }
    }
    
    static var matchingTolerance = 0.000001
    
    static func match(pants0: Pants, index0: Int, pants1: Pants, index1: Int, twist: Double) {
        assert((pants0.cuffHalfLengths[index0] - pants1.cuffHalfLengths[index1]).abs < matchingTolerance)
        // YOU SHOULD PROBABLY MAKE THE CUFFS EXACTLY EQUAL IF THEY ARE NOT ALREADY
        pants0.adjacenciesAndTwists[index0] = (pants1, index1, twist)
        pants1.adjacenciesAndTwists[index1] = (pants0, index0, twist)
    }
    
    
}