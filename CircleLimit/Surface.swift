//
//  Surface.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 9/14/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

struct LocationData {
    
    var hexagon: Hexagon
    var localMask: HTrans
    
}

class Surface {
    
    var pantsArray: [Pants] = []
    var cuffArray: [Cuff] = []
    var baseHexagon: Hexagon!
    var shadowHexagon: Hexagon?
    var shadowHexagonIndex: Int?
    
    // MARK: Location information
    var mask: HyperbolicTransformation = HyperbolicTransformation.identity
    var currentLocation: LocationData {
        return LocationData(hexagon: baseHexagon, localMask: mask)
    }
    
    // MARK: Group information
    // This is now total garbage
    var groupoid: [EndState] {
        let x: [EndState] = []
        return x
    }
    var group: [HTrans] = []  // Or [Action]?
    
    // MARK: Guidelines
//    var hexagonTesselation: [HDrawable] = []
    var generalGuidelines: [LocatedObject] = []
    var cuffGuidelines: [LocatedObject] = []
    
    // MARK: Initializers
    init(pantsArray: [Pants], cuffArray: [Cuff]) {
        self.pantsArray = pantsArray
        self.cuffArray = cuffArray
        baseHexagon = pantsArray[0].hexagons[0]
    }
    
    // MARK: Deliver masks for drawing, etc.
    func visibleMasks(object: Disked, location: LocationData, radius: Double) -> [HTrans] {
        let M = location.localMask
        let r = object.radius
        let distance = Int(M.distance + r + mask.distance + radius)
        let g = baseHexagon.groupoidTo(location.hexagon, withDistance: distance)
        let gg = g.map({mask.following($0.motion).following(M)})
        return gg.filter({$0.appliedTo(object.centerPoint).distanceToOrigin  < radius + r})
    }
    
    
    // MARK: Alter the mask
    var searchDistance = 4

    func applyToMask(M: HTrans) {
        mask = M.following(mask)
    }
    
    // TODO: Maintain a smaller searching groupoid?
    func recomputeMask() {
        var searchStates: [EndState] = []
        for h in baseHexagon.groupoid.keys {
            searchStates += baseHexagon.groupoidTo(h, withDistance: searchDistance)
        }
        let bestNewEndstate = searchStates.leastElementFor({self.mask.appliedTo($0.motion.appliedToOrigin).abs})!
        if bestNewEndstate.motion.abs > 0.00001 {
            shiftBaseHexagon(newBase: bestNewEndstate)
        }
    }
    
    // TODO: Deal with the shadow hexagon
    func shiftBaseHexagon(newBase: EndState) {
        baseHexagon = newBase.hexagon
        baseHexagon.computeInitialGroupoid(timeLimitInMilliseconds: 200, maxDistance: 7)
        mask = mask.following(newBase.motion)
        print("New base hexagon with id \(baseHexagon.id))")
    }
    
    
    // MARK: Setting stuff up
    
    // DEPRECATED: We're not really using the group anymore
//    func setupGroupFromGroupoid() {
//        group = groupFromEndStates(groupoid, for: baseHexagon)
//        if let shadowHexagon = shadowHexagon {
//            /* the '4' in downFromOrthocenter[4] is because the 0 side for hexagons[0] forms a contiguous cuff with the 4 side for hexagons[1]
//             */
//            group += groupFromEndStates(groupoid, for: shadowHexagon).map({$0.following(shadowHexagon.downFromOrthocenter[shadowHexagonIndex!]).flip})
//        }
//    }

    // We should probably give this a new name
    func setupGroupoidAndGroup(timeLimitInMilliseconds: Int, maxDistance: Int) {
        baseHexagon.computeInitialGroupoid(timeLimitInMilliseconds: timeLimitInMilliseconds, maxDistance: maxDistance)
//        setupGroupFromGroupoid()
    }
    
    func setUpGuidelines() {
        generalGuidelines = pantsArray.flatMap({$0.guidelines})
        cuffGuidelines = cuffArray.map() {$0.guideline}
    }
    
}



