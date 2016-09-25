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
    
    var groupoid: [EndState] = []
    var group: [HTrans] = []  // Or [Action]?
    
    var hexagonTesselation: [HDrawable] = []
    var generalGuidelines: [HDrawable] = []
//    var hexagonGuidelines: [HDrawable] = []
    var cuffGuidelines: [HDrawable] = []
    
    init(pantsArray: [Pants], cuffArray: [Cuff]) {
        self.pantsArray = pantsArray
        self.cuffArray = cuffArray
        baseHexagon = pantsArray[0].hexagons[0]
    }
    
    func setupGroupoidAndGroupForDistance(distance: Double) {
        groupoid = baseHexagon.groupoidForDistance(distance)
        group = groupFromEndStates(groupoid, for: baseHexagon)
        if let shadowHexagon = shadowHexagon {
            /* the '4' in downFromOrthocenter[4] is because the 0 side for hexagons[0] forms a contiguous cuff with the 4 side for hexagons[1]
             */
            group += groupFromEndStates(groupoid, for: shadowHexagon).map({$0.following(shadowHexagon.downFromOrthocenter[4]).flip})
        }
        
    }
    
    func setupGroupoidAndGroupForSteps(numberOfSteps: Int) {
        //        drawOnlyHexagonTesselation = true
        var steppedStates: [[ForwardState]] = [baseHexagon.forwardStates]
        for i in 0..<numberOfSteps {
            steppedStates.append(steppedStates.last!.flatMap(nextForwardStates))
            print("At stage \(i) in adding new states for a total of \(steppedStates.flatten().count) states")
        }
        groupoid = steppedStates.flatten().map(project) + [EndState(motion: HTrans(), hexagon: baseHexagon)]
        hexagonTesselation = steppedStates.flatten().map() { $0.lineToDraw }
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
