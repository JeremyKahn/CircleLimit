//
//  TestType.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 9/14/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

enum TestType {
    case orbiFour(Int, Int, Int, Int)
    case triangle(Int, Int, Int)
    case orbiTorus(Int)
    case pants
    case t2223
    case reflectedTriangle(Int, Int, Int)
    
    var numberOfPants: Int {
        switch self {
        case triangle, .orbiTorus, .t2223, .reflectedTriangle: return 1
        case orbiFour, pants: return 2
        }
    }
    
    var numberOfStepsToTake: Int {
        switch self {
        case .triangle: return 15
        case .reflectedTriangle: return 10
        case pants: return 5
        case orbiFour, .t2223: return 10
        case .orbiTorus: return 7
        }
    }
    
    var distanceToGo: Double {
        switch self {
        case .triangle: return 7.0
        case .reflectedTriangle: return 7.0
        case orbiFour, .t2223: return 7.0
        case orbiTorus, pants: return 10.0
        }
    }
    
    var pantsAndCuffPlaceholders: ([PantsPlaceholder], [CuffPlaceholder]) {
        var pants: [PantsPlaceholder] = []
        var cuffs: [CuffPlaceholder] = []
        switch self {
        case .pants:
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1)
            let cuff2 = CuffPlaceholder(halfLength: 2, twist: 0.2)
            let cuff3 = CuffPlaceholder(halfLength: 3, twist: 0.3)
            cuffs = [cuff1, cuff2, cuff3]
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff(c: cuff1), NumberCuff(c: cuff2), NumberCuff(c: cuff3)]))
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff(c: cuff1), NumberCuff(c: cuff2), NumberCuff(c: cuff3)]))
        case .reflectedTriangle(let p, let q, let r):
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff.number(q), NumberCuff.number(r)], type: .threeZeroHalf))
        case .triangle(let p, let q, let r):
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff.number(q), NumberCuff.number(r)]))
        case .orbiTorus(let p):
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1)
            cuffs = [cuff1]
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff(c: cuff1), NumberCuff(c: cuff1)]))
        case .orbiFour(let p, let q, let r, let s):
            let m = 84000000
            if m/p + m/q >= m ||  m/r + m/s >= m {
                fatalError("Bad inputs: \(p, q, r, s)")
            }
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1)
            cuffs = [cuff1]
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff.number(q), NumberCuff(c: cuff1)]))
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(r), NumberCuff.number(s), NumberCuff(c: cuff1)]))
        case .t2223:
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1)
            cuffs = [cuff1]
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(2), NumberCuff.number(3), NumberCuff(c: cuff1, type: .folded)]))
        }
        return (pants, cuffs)
    }
    
    var surface: Surface {
        let (pantsPlaceholders, cuffPlaceholders) = pantsAndCuffPlaceholders
        let result = surfaceFromPlaceholders(pantsPlaceholders, cuffPlaceholders: cuffPlaceholders)
        if numberOfPants >= 1 { result.pantsArray[0].color = UIColor.greenColor() }
        if numberOfPants >= 2 { result.pantsArray[1].color = UIColor.blueColor() }
        return result
    }
    
}

