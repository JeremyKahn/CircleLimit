//
//  Hexagon.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

class Hexagon {
    
    var sideLengths: [Double] = Array<Double>(count: 6, repeatedValue: acosh(2.0))
    
    var firstParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var secondParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var altitudeParts: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var downFromOrthocenter: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var angleToNextAltitude: [Double] = Array<Double>(count: 6, repeatedValue: 0.0)
    
    var foot: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var start: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var middle: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)
    
    var end: [HUVect] = [HUVect](count: 6, repeatedValue: HTrans.identity)

    var sideGuidelines: [HDrawable] = []
    
    var altitudeGuidelines: [HDrawable] = []
    
    var guidelines: [HDrawable] {
        return sideGuidelines + altitudeGuidelines
    }

    init(alternatingSideLengths: [Double]) {
        for i in 0..<3 {
            sideLengths[2 * i] = alternatingSideLengths[i]
        }
        for i in 1.stride(through: 5, by: 2) {
            let (A, B, C) = (sideLengths[(i + 3) %% 6], sideLengths[(i - 1) %% 6], sideLengths[(i + 1) %% 6])
            let num = cosh(B) * cosh(C) + cosh(A)
            let denom = sinh(B) * sinh(C)
            sideLengths[i] = acosh(num/denom)
        }
        setUpEverything()
    }
    
    func copy() -> Hexagon {
        let alternatingSideLengths = [sideLengths[0], sideLengths[2], sideLengths[4]]
        return Hexagon(alternatingSideLengths: alternatingSideLengths)
    }
    
    func setUpEverything() {
        for i in 0..<6 {
            firstParts[i] = acoth(cosh(sideLengths[(i - 1) %% 6]) / coth(sideLengths[(i - 2) %% 6]))
            secondParts[i] = acoth(cosh(sideLengths[(i + 1) %% 6]) / coth(sideLengths[(i + 2) %% 6]))
        }
        for i in 0..<6 {
            altitudeParts[i] = atanh(cosh(firstParts[i]) * tanh(secondParts[(i - 1) %% 6]))
            // This is redundant because angleToNextAltitude[i + 3] == angleToNextAltitude[i]
            angleToNextAltitude[i] = acos(sinh(secondParts[i]) * sinh(firstParts[(i + 1) % 6]))
        }
        // Here we're using that downFromOrthocenter[0] is HTrans.identity
        for i in 0..<5 {
            downFromOrthocenter[i + 1] = downFromOrthocenter[i].rotate(angleToNextAltitude[i])
        }
        for i in 0..<6 {
            foot[i] = downFromOrthocenter[i].goForward(altitudeParts[i])
            middle[i] = foot[i].turnLeft
            end[i] = middle[i].goForward(secondParts[i])
            start[i] = middle[i].goForward(-firstParts[i])
        }
        sideGuidelines = []
        for i in 0..<6 {
            let line = HyperbolicPolyline([start[i].appliedToOrigin, end[i].appliedToOrigin])
            sideGuidelines.append(line)
        }
        altitudeGuidelines = []
        for i in 0..<6 {
            let line = HyperbolicPolyline([HPoint(), foot[i].appliedToOrigin])
            altitudeGuidelines.append(line)
        }
    }
    
}