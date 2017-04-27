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
        setUpTestSurface()
        setUpGroupAndGuidelinesForPants()
    }
    
    func setUpTestSurface() {
        surface = testType.surface
        largeGenerationDistance = testType.distanceToGo
        groupGenerationCutoffDistance = largeGenerationDistance
    }
    
    // This guy is deprecated and is not necessarily being maintained
    func setUpThreeThreeFourGroup() {
        var generators: [HyperbolicTransformation] = []
        var guidelines: [HDrawable] = []
        var twistedGenerators: [Action] = []
        if !trivialGroup {
            (generators, guidelines) = pqrGeneratorsAndGuidelines(3, q: 3, r: 4)
            for object in guidelines {
                object.intrinsicLineWidth = 0.005
                object.lineColor = UIColor.gray
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
        let bigGroup = generatedGroup(twistedGenerators, bigCutoff: bigGroupCutoff)
        makeGroupForIntegerDistanceWith(bigGroup)
        // Right now this is just a guess
        let I = ColorNumberPermutation()
        searchingGroup = groupForIntegerDistance[5].filter() { $0.action == I }
    }
    
    // We're assuming here that the pants have already had their cuffHalfLengths set
    // And now we're computing the groupoid, the group, and the guidelines, and then setting up all the group segments
    func setUpGroupAndGuidelinesForPants() {
        if serious {
            print("Generating group in time \(groupGenerationTimeLimit)")
            surface.setupGroupoidAndGroup(timeLimitInMilliseconds: groupGenerationTimeLimit, maxDistance: visibleDistance)
        } else {
            drawOnlyHexagonTesselation = true
            surface.setupGroupoidAndGroupForSteps(testType.numberOfStepsToTake)
        }
        let group = trivial || drawOnlyHexagonTesselation  ? [HTrans()] : surface.group
        
        surface.setUpHexagonsAndGuidelines()
        if let i = cuffEditIndex {
            surface.cuffGuidelines[i].lineColor = UIColor.red
        }

        // Set up the groups
        let dressedGroup = group.map() {Action(M: $0)}
        makeGroupForIntegerDistanceWith(dressedGroup)
        searchingGroup = groupForIntegerDistance[min(maxGroupDistance, surface.estimatedDiameter)]
    }
    
}
