//
//  Surface.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 9/14/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

class Surface {
    
    var pantsArray: [Pants] = []
    var cuffArray: [Cuff] = []
    var baseHexagon: Hexagon!
    var shadowHexagon: Hexagon?
    var shadowHexagonIndex: Int?
    
    var groupoid: [EndState] = []
    var group: [HTrans] = []  // Or [Action]?
    
    var hexagonTesselation: [HDrawable] = []
    var generalGuidelines: [HDrawable] = []
    var cuffGuidelines: [HDrawable] = []
    
    init(pantsArray: [Pants], cuffArray: [Cuff]) {
        self.pantsArray = pantsArray
        self.cuffArray = cuffArray
        baseHexagon = pantsArray[0].hexagons[0]
    }
    
    func setupGroupFromGroupoid() {
        group = groupFromEndStates(groupoid, for: baseHexagon)
        if let shadowHexagon = shadowHexagon {
            /* the '4' in downFromOrthocenter[4] is because the 0 side for hexagons[0] forms a contiguous cuff with the 4 side for hexagons[1]
             */
            group += groupFromEndStates(groupoid, for: shadowHexagon).map({$0.following(shadowHexagon.downFromOrthocenter[shadowHexagonIndex!]).flip})
        }
    }
    
    func setupGroupoidAndGroup(timeLimitInMilliseconds: Int, maxDistance: Int) {
        groupoid = baseHexagon.prioritizedGroupoid(timeLimitInMilliseconds: timeLimitInMilliseconds, maxDistance: maxDistance)
        setupGroupFromGroupoid()
    }
    
    // This will all have to be rewritten so that we can send a pipeline of new elements
    // We should also move the Groups for Integer Distance to
    func augmentGroupoidAndGroup(timeLimitInMilliseconds: Int, maxDistance: Int, mask: HyperbolicTransformation) {
        groupoid += baseHexagon.newGroupoidElements(timeLimitInMilliseconds: timeLimitInMilliseconds, maxDistance: maxDistance, mask: mask)
        setupGroupFromGroupoid()
    }
    
//    func setupGroupoidAndGroupForDistance(_ distance: Double) {
//        groupoid = baseHexagon.groupoidForDistance(distance)
//        setupGroupFromGroupoid()
//     }
    
    func setupGroupoidAndGroupForSteps(_ numberOfSteps: Int) {
        //        drawOnlyHexagonTesselation = true
        var steppedStates: [[ForwardState]] = [baseHexagon.forwardStates]
        for i in 0..<numberOfSteps {
            steppedStates.append(steppedStates.last!.flatMap(nextForwardStates))
            print("At stage \(i) in adding new states for a total of \(steppedStates.joined().count) states")
        }
        groupoid = steppedStates.joined().map(project) + [EndState(motion: HTrans(), hexagon: baseHexagon)]
        hexagonTesselation = steppedStates.joined().map() { $0.lineToDraw }
    }
    
    func setUpHexagonsAndGuidelines() {
        generalGuidelines = []
        
        for Q in pantsArray {
            for i in 0...1 {
                let hexagon = Q.hexagons[i]
                let morphismsToHexagon = groupoid.filter({$0.hexagon === hexagon})
                if let motion = morphismsToHexagon.map({$0.motion}).leastElementFor({$0.distance}) {
                    hexagon.baseMask = motion
                }
            }
            generalGuidelines += Q.transformedGuidelines
        }
        cuffGuidelines = cuffArray.map() {$0.transformedGuideline}
    }
    
}
