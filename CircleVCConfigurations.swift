//
//  CircleVCConfigurations.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/3/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

extension CircleViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("CircleViewController loaded")
        makeInitialPants()
        setUpBothPants()
    }
    
    func setUpThreeThreeFourGroup() {
        var generators: [HyperbolicTransformation] = []
        var guidelines: [HDrawable] = []
        var twistedGenerators: [Action] = []
        if !trivialGroup {
            (generators, guidelines) = pqrGeneratorsAndGuidelines(3, q: 3, r: 4)
            for object in guidelines {
                object.intrinsicLineWidth = 0.005
                object.lineColor = UIColor.grayColor()
                object.useFillColorTable = false
            }
            
            // This will show the fixed points of all the elliptic elements
            //            guidelines.append(HyperbolicDot(center: HPoint()))
            for g in generators {
                let fixedPointDot = HyperbolicDot(center: g.fixedPoint!)
                self.fixedPoints.append(fixedPointDot)
            }
            
            let (A, B, C) = (generators[0], generators[1], generators[2])
            let a = ColorNumberPermutation(mapping: [1: 2, 2: 3, 3: 1, 4: 4])
            let b = ColorNumberPermutation(mapping: [1: 1, 2: 3, 3: 4, 4: 2])
            let c = ColorNumberPermutation(mapping: [1: 2, 2: 1, 3: 4, 4: 3])
            assert(a.following(b).following(c) == ColorNumberPermutation())
            twistedGenerators = [Action(M: A, P: a), Action(M: B, P: b), Action(M: C, P: c)]
        }
        self.guidelines = guidelines
        let bigGroup = generatedGroup(twistedGenerators, bigCutoff: bigGroupCutoff)
        makeGroupForIntegerDistanceWith(bigGroup)
        // Right now this is just a guess
        let I = ColorNumberPermutation()
        searchingGroup = groupForIntegerDistance[5].filter() { $0.action == I }
    }
    
    // We're going to work first with two pants with the i'th cuffs joined
    func makeInitialPants() {
        let pants0 = Pants(cuffHalfLengths: cuffLengths)
        let pants1 = Pants(cuffHalfLengths: cuffLengths)
        for i in 0...2 {
            Pants.match(pants0, index0: i, pants1: pants1, index1: i, twist: 0.5)
        }
        pantsArray = [pants0, pants1]
        for p in pantsArray {
            p.setUpGroupoidElementsToAdjacentPants()
        }
    }
        
    // We're assuming here that the pants have already had their cuffHalfLengths set
    // And now we're computing the groupoid, the group, and the guidelines, and then setting up all the group segments
    func setUpBothPants() {
        pants = pantsArray[0]
        let baseHexagon = pants.hexagons[0]
        let groupoidGenerators = pantsArray.reduce([], combine: {$0 + $1.groupoidGenerators})
        let base = [GroupoidElement(M: HTrans(), start: baseHexagon, end: baseHexagon)]
        let groupoid = generatedGroupoid(base, generators: groupoidGenerators, withinBounds: {$0.M.distance < 12.0}, maxTime: 10.0)
        let group = groupFromGroupoid(groupoid, startingAndEndingAt: baseHexagon)
        guidelines = []
        for Q in pantsArray {
            for i in 0...1 {
                let hexagon = Q.hexagons[i]
                let motion = leastElementOfGroupoid(groupoid, toGoFrom: baseHexagon, to: hexagon)!.M
                let hexagonGuidelines = hexagon.guidelines.map({$0.transformedBy(motion)})
                guidelines += hexagonGuidelines
            }
        }
        let dressedGroup = group.map() {Action(M: $0)}
        makeGroupForIntegerDistanceWith(dressedGroup)
        searchingGroup = groupForIntegerDistance[min(7, maxGroupDistance)]        
    }
    
}