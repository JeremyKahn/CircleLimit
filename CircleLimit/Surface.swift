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
}

// TODO: Set up a GroupManager protocol and change CircleViewController so that it owns a GroupManager
class Surface {
    
    var pantsArray: [Pants] = []
    var cuffArray: [Cuff] = []
    var baseHexagon: Hexagon!
    var hasReflection = false
    var hexagons: [Hexagon] {
        return pantsArray.flatMap({$0.hexagons})
    }
    
    // MARK: Location information
    var mask: HyperbolicTransformation = HyperbolicTransformation.identity
    var currentLocation: LocationData {
        return LocationData(hexagon: baseHexagon)
    }
    
    
    // MARK: Guidelines
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
        return visibleMasks(object: object, location: location, radius: radius, center: HPoint(), useMask: true)
    }
    
    func visibleMasks(object: Disked, location: LocationData, radius: Double, center: HPoint, useMask: Bool) -> [HTrans] {
        let m = useMask ? mask : HTrans.identity
        let r = object.radius
        let distance = r + m.distance + radius + center.distanceToOrigin
        var g = baseHexagon.groupoidTo(location.hexagon, withDistance: distance).map() {$0.motion}
        if hasReflection {
            let shadowHexagon = location.hexagon.shadowHexagon!
            let shadowIndex = location.hexagon.shadowHexagonIndex!
            let gShadow = baseHexagon.groupoidTo(shadowHexagon, withDistance: distance).map()
            {$0.motion.following(shadowHexagon.downFromOrthocenter[shadowIndex]).flip}
            g += gShadow
        }
        let gg = g.map({m.following($0)})
        return gg.filter({$0.appliedTo(object.centerPoint).distanceTo(center)  < radius + r})
    }
    
    
    // MARK: Alter the mask
    var searchDistance = absToDistance(0.99)

    func applyToMask(M: HTrans) {
        mask = M.following(mask)
    }
    
    // TODO: Get sensible time and distance limits from the caller
    func recomputeMask() {
        var searchStates: [EndState] = []
        for h in baseHexagon.groupoid.keys {
            searchStates += baseHexagon.groupoidTo(h, withDistance: searchDistance)
        }
        let bestNewEndstate = searchStates.leastElementFor({self.mask.appliedTo($0.motion.appliedToOrigin).abs})!
        if bestNewEndstate.motion.abs > 0.00001 {
            shiftBaseHexagon(newBase: bestNewEndstate)
        }
        baseHexagon.recomputeGroupoid(timeLimitInMilliseconds: 200, maxDistance: 7, mask: mask)
    }
    
    // TODO: Deal with the shadow hexagon
    func shiftBaseHexagon(newBase: EndState) {
        baseHexagon = newBase.hexagon
        mask = mask.following(newBase.motion)
        print("New base hexagon with id \(baseHexagon.id)")
    }
    
    
    // MARK: Setting stuff up
    
    // We should probably give this a new name
    func setupGroupoidAndGroup(timeLimitInMilliseconds: Int, maxDistance: Int) {
        for h in hexagons {
            h.resetGroupoid()
        }
        baseHexagon.recomputeGroupoid(timeLimitInMilliseconds: timeLimitInMilliseconds, maxDistance: maxDistance, mask: mask)
    }
    
    func setUpGuidelines() {
        generalGuidelines = pantsArray.flatMap({$0.guidelines})
        cuffGuidelines = cuffArray.map() {$0.guideline}
    }
    
}



