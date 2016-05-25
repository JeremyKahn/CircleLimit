//
//  Diapers.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/23/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

var geodesicCutoffDistance: Double = 5

typealias GDict = LocationDictionary<HeuristicGeodesic, HTrans>

var geodesicDictionary =  [GDict](count: 3, repeatedValue: GDict())

var geodesicRepresentatives: [[HTrans]] = [[HTrans]](count: 3, repeatedValue: [])

var nonbaseGeodesicRepresentatives: [[HTrans]] = [[HTrans]](count: 3, repeatedValue: [])


func setUpGeodesicRepresentatives() {
    for i in 0...2 {
        geodesicDictionary[i] = GDict()
        let tM = tMinus[i]
        let baseGeodesic = HeuristicGeodesic(v: tM)
        for g in group {
            let geodesic = g.appliedTo(baseGeodesic)
            let prospectiveNewRep = g.following(tM)
            if let rep = geodesicDictionary[i][geodesic] {
                if prospectiveNewRep.distance < rep.distance {
                    geodesicDictionary[i].updateValue(prospectiveNewRep, forKey: geodesic)
                }
            } else {
                if prospectiveNewRep.distance < geodesicCutoffDistance {
                    geodesicDictionary[i].updateValue(prospectiveNewRep, forKey: geodesic)
                }
            }
            let dummy1 = 0
        }
        geodesicRepresentatives[i] = geodesicDictionary[i].values
        nonbaseGeodesicRepresentatives[i] = geodesicRepresentatives[i].filter() {
            !HeuristicGeodesic(v: $0).matches(baseGeodesic)
        }
        let dummy = 0
    }
    
    // MARK: Total Group
    // Here we're computing the total group _recursively_
    // which is fine as long as we don't run out of time
    func totalGroupForHalfPlaneAtVector(v: HTrans, withIndex i: Int) -> [HTrans] {
        guard HeuristicGeodesic(v: v).approximateDistanceToOrigin < geodesicCutoffDistance else {
            return []
        }
        let vM0 = tMinus[i]
        let g0 = group // There should be filtering!
        let R = v.following(vM0.inverse)
        let g1 = g0.map() {R.following($0).following(R.inverse)}
        // TODO: Remove redundant elements of the group
        var result = g1
        for j in 0...2 {
            var vectors = nonbaseGeodesicRepresentatives[j]
            vectors = vectors.map() {R.following($0)}
            for vector in vectors {
                let maybeM = MatchingVector(P: self, v: vector, i: j).match
                guard let M = maybeM else {continue}
                var g = M.P.totalGroupForHalfPlaneAtVector(M.v, withIndex: M.i)
                g = g.filter(withinRange)
                result += g
            }
        }
        return result
    }
    
    var totalGroup: [HTrans] {
        var result: [HTrans] = group
        for i in 0...2 {
            for v in geodesicRepresentatives[i] {
                let maybeM = MatchingVector(P: self, v: v, i: i).match
                guard let M = maybeM else {continue}
                var g = M.P.totalGroupForHalfPlaneAtVector(M.v, withIndex: M.i)
                g = g.filter(withinRange)
                result += g
            }
        }
        return result
    }
    
    

}
