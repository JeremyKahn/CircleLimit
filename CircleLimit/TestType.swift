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
    case reflectedT2223
    case reflectedTriangle(Int, Int, Int)
    case angelsAndDevils
    
    var numberOfStepsToTake: Int {
        switch self {
        case .triangle: return 15
        case .reflectedTriangle, .angelsAndDevils: return 10
        case .pants: return 5
        case .orbiFour, .t2223, .reflectedT2223: return 10
        case .orbiTorus: return 7
        }
    }
    
    var distanceToGo: Double {
        switch self {
        case .triangle: return 7.0
        case .reflectedTriangle, .angelsAndDevils: return 7.0
        case .orbiFour, .t2223, .reflectedT2223: return 7.0
        case .orbiTorus, .pants: return 10.0
        }
    }
    
    var pantsPlaceholders: [PantsPlaceholder] {
        var pants: [PantsPlaceholder] = []
        switch self {
        case .pants:
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1)
            let cuff2 = CuffPlaceholder(halfLength: 2, twist: 0.2)
            let cuff3 = CuffPlaceholder(halfLength: 3, twist: 0.3)
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff(c: cuff1), NumberCuff(c: cuff2), NumberCuff(c: cuff3)]))
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff(c: cuff1), NumberCuff(c: cuff2), NumberCuff(c: cuff3)]))
        case .reflectedTriangle(let p, let q, let r):
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff.number(q), NumberCuff.number(r)], type: .threeZeroHalf))
        case .triangle(let p, let q, let r):
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff.number(q), NumberCuff.number(r)]))
        case .angelsAndDevils:
            pants.append(PantsPlaceholder(halfCuff: NumberCuff.number(3), wholeCuff: NumberCuff.number(4)))
        case .orbiTorus(let p):
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1)
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff(c: cuff1), NumberCuff(c: cuff1)]))
        case .orbiFour(let p, let q, let r, let s):
            let m = 84000000
            if m/p + m/q >= m ||  m/r + m/s >= m {
                fatalError("Bad inputs: \(p, q, r, s)")
            }
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1)
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(p), NumberCuff.number(q), NumberCuff(c: cuff1)]))
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(r), NumberCuff.number(s), NumberCuff(c: cuff1)]))
        case .t2223:
            let cuff1 = CuffPlaceholder(halfLength: 1, twist: 0.1, type: .folded)
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(2), NumberCuff.number(3), NumberCuff(c: cuff1)]))
        case .reflectedT2223:
            let cuff1 = CuffPlaceholder(halfLength: 1, type: .folded)
            pants.append(PantsPlaceholder(cuffArray: [NumberCuff.number(2), NumberCuff.number(3), NumberCuff(c: cuff1)], type: PantsPlaceholderType.threeZeroHalf))
        }
        return pants
    }
    
    var surface: Surface {
        let pants = pantsPlaceholders
        let result = surfaceFromPlaceholders(pants)
        if result.pantsArray.count >= 1 { result.pantsArray[0].color = UIColor.green }
        if result.pantsArray.count >= 2 { result.pantsArray[1].color = UIColor.blue }
        return result
    }
    
}

