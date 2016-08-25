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
        if CircleViewController.testing { return }
        makeInitialPants()
        setUpGroupAndGuidelinesForPants()
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
        self.generalGuidelines = guidelines
        let bigGroup = generatedGroup(twistedGenerators, bigCutoff: bigGroupCutoff)
        makeGroupForIntegerDistanceWith(bigGroup)
        // Right now this is just a guess
        let I = ColorNumberPermutation()
        searchingGroup = groupForIntegerDistance[5].filter() { $0.action == I }
    }
    
    
    
    // We're going to work first with two pants with the i'th cuffs joined
    func makeInitialPants() {
        let pants0 = Pants(cuffHalfLengths: cuffLengths)
        pants0.setColor(UIColor.blueColor())
        let pants1 = Pants(cuffHalfLengths: cuffLengths)
        pants1.setColor(UIColor.greenColor())
        for i in 0...2 {
            cuffArray.append(Cuff(pants0: pants0, index0: i, pants1: pants1, index1: i, twist: 0.0))
        }
        pantsArray = [pants0, pants1]
    }
    
    // We're assuming here that the pants have already had their cuffHalfLengths set
    // And now we're computing the groupoid, the group, and the guidelines, and then setting up all the group segments
    func setUpGroupAndGuidelinesForPants() {
        pants = pantsArray[0]
        let baseHexagon = pants.hexagons[0]
        
        print("Generating group for distance \(groupGenerationCutoffDistance)")
        let endStates = baseHexagon.allMorphisms(groupGenerationCutoffDistance)
         //        var steppedStates: [[ForwardState]] = [baseHexagon.forwardStates]
        //        for _ in 0...5 {
        //            steppedStates.append(steppedStates.last!.map(nextForwardStates).flatten().map({$0}))
        //        }
        //        let endStates = steppedStates.flatten().map(project)
        let group = groupFromEndStates(endStates, for: baseHexagon)
        
        cuffGuidelines = []
        for cuff in cuffArray {
            cuffGuidelines.append(cuff.transformedGuideline)
        }
        if let i = cuffEditIndex {
            cuffGuidelines[i].lineColor = UIColor.redColor()
        }
        
        for Q in pantsArray {
            for i in 0...1 {
                let hexagon = Q.hexagons[i]
                let morphismsToHexagon = endStates.filter({$0.hexagon === hexagon})
                let motion = morphismsToHexagon.map({$0.motion}).leastElementFor({$0.distance})
                hexagon.baseMask = motion
            }
        }
        
        generalGuidelines = []
        for Q in pantsArray {
            generalGuidelines += Q.transformedGuidelines
            //            for i in 0...1 {
            //                let hexagon = Q.hexagons[i]
            //                let altitudeGuidelines = hexagon.altitudeGuidelines.map({$0.transformedBy(hexagon.baseMask)})
            //                generalGuidelines += altitudeGuidelines
            //            }
        }
        let dressedGroup = group.map() {Action(M: $0)}
        makeGroupForIntegerDistanceWith(dressedGroup)
        searchingGroup = groupForIntegerDistance[min(7, maxGroupDistance)]
    }
    
}