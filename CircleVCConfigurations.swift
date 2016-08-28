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
        makeInitialGeneralPants()
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
    
    
    
    
    enum TestType {
        case t2323, t334, pants, torus2
    }
    
    func makeInitialGeneralPants() {
        let testType = TestType.t334
        switch testType {
        case .pants:
            let pants0 = Pants(cuffHalfLengths: cuffLengths)
            pants0.setColor(UIColor.blueColor())
            let pants1 = Pants(cuffHalfLengths: cuffLengths)
            pants1.setColor(UIColor.greenColor())
            for i in 0...2 {
                cuffArray.append(Cuff(pants0: pants0, index0: i, pants1: pants1, index1: i, twist: 0.0))
            }
            pantsArray = [pants0, pants1]
        case .t2323:
            let cph0 = CuffPlaceholder()
            let pph0 = PantsPlaceholder()
            let pph1 = PantsPlaceholder()
            pph0.numberCuffArray = [NumberCuff.number(2), NumberCuff.number(3), NumberCuff.cuff(cph0, 0)]
            pph1.numberCuffArray = [NumberCuff.number(3), NumberCuff.number(5), NumberCuff.cuff(cph0, 1)]
            (pantsArray, cuffArray) = pantsAndCuffArrayFromPlaceholders([pph0, pph1])
            pantsArray[0].setColor(UIColor.blueColor())
            pantsArray[1].setColor(UIColor.greenColor())
        case .t334:
            let pph = PantsPlaceholder()
            pph.numberCuffArray = [NumberCuff.number(3), NumberCuff.number(4), NumberCuff.number(5)]
            (pantsArray, cuffArray) = pantsAndCuffArrayFromPlaceholders([pph])
            pantsArray[0].setColor(UIColor.greenColor())
        case .torus2:
            let pph = PantsPlaceholder()
            let cph = CuffPlaceholder()
            pph.numberCuffArray = [NumberCuff.number(2), NumberCuff.cuff(cph, 0), NumberCuff.cuff(cph, 1)]
            (pantsArray, cuffArray) = pantsAndCuffArrayFromPlaceholders([pph])
            pantsArray[0].setColor(UIColor.blueColor())
        }
        
    }
    
    // We're assuming here that the pants have already had their cuffHalfLengths set
    // And now we're computing the groupoid, the group, and the guidelines, and then setting up all the group segments
    func setUpGroupAndGuidelinesForPants() {
        pants = pantsArray[0]
        let baseHexagon = pants.hexagons[0]
        
        let serious = true
        let trivial = false
        var endStates: [EndState] = []
        if serious {
            print("Generating group for distance \(groupGenerationCutoffDistance)")
            endStates = baseHexagon.allMorphisms(groupGenerationCutoffDistance)
        } else {
            var steppedStates: [[ForwardState]] = [baseHexagon.forwardStates]
            for _ in 0...9 {
                steppedStates.append(steppedStates.last!.map(nextForwardStates).flatten().map({$0}))
            }
            endStates = steppedStates.flatten().map(project) + [EndState(motion: HTrans(), hexagon: baseHexagon)]
            hexagonTesselation =  endStates.map() { $0.translatedHexagon } + steppedStates.flatten().map() { $0.lineToDraw }
        }
        let group = trivial || drawOnlyHexagonTesselation ? [HTrans()] : groupFromEndStates(endStates, for: baseHexagon)
        
        // Set up the cuff Guidelines
        cuffGuidelines = []
        for cuff in cuffArray {
            cuffGuidelines.append(cuff.transformedGuideline)
        }
        if let i = cuffEditIndex {
            cuffGuidelines[i].lineColor = UIColor.redColor()
        }
        
        if !drawOnlyHexagonTesselation {
            // Compute the baseMask for each hexagon for each pants
            for Q in pantsArray {
                for i in 0...1 {
                    let hexagon = Q.hexagons[i]
                    let morphismsToHexagon = endStates.filter({$0.hexagon === hexagon})
                    let motion = morphismsToHexagon.map({$0.motion}).leastElementFor({$0.distance})!
                    hexagon.baseMask = motion
                }
            }
            
            // The generalGuidelines will include the transformed guidelines for the pants
            generalGuidelines = []
            let firstPantsOnly = false
            for Q in (firstPantsOnly ? [pantsArray[0]] : pantsArray) {
                generalGuidelines += Q.transformedGuidelines
                //            for i in 0...1 {
                //                let hexagon = Q.hexagons[i]
                //                let altitudeGuidelines = hexagon.altitudeGuidelines.map({$0.transformedBy(hexagon.baseMask)})
                //                generalGuidelines += altitudeGuidelines
                //            }
            }
        }
        
    
        // Set up the groups
        let dressedGroup = group.map() {Action(M: $0)}
        makeGroupForIntegerDistanceWith(dressedGroup)
        searchingGroup = groupForIntegerDistance[min(7, maxGroupDistance)]
    }
    
}