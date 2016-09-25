//
//  PantsMaker.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 8/26/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

/// Keeps track of two NumberCuff's that in turn point back here, so that they can find each other
class CuffPlaceholder {
    
    var pantsCuffArrays: [[PantsCuff]] = [[], []]
    
    var halfLength = 1.0
    
    var twist = 0.0
    
    init(halfLength: Double, twist: Double) {
        self.halfLength = halfLength
        self.twist = twist
    }
    
    // Should be used for any cuff where there's any kind of reflection
    init(halfLength: Double) {
        self.halfLength = halfLength
    }

    /// This should be called only once!
    var cuffArray: [Cuff] {
        let pantsCuffArray0 = pantsCuffArrays[0]
        let pantsCuffArray1 = pantsCuffArrays[1]
        var result: [Cuff] = [Cuff(pantsCuff0: pantsCuffArray0[0], pantsCuff1: pantsCuffArray0[1], twist: twist)]
        if pantsCuffArrays[1].count > 0 {
            result.append(Cuff(pantsCuff0: pantsCuffArray1[0], pantsCuff1: pantsCuffArray1[1], twist: -twist))
        }
        return result
    }
    
}

enum CuffType {
    case normal, folded, reflected, glideReflected
}


/// A number or a cuff: the number is at least 2, and the cuff can find its match
enum NumberCuff {
    
    case number(Int)
    
    case cuff(CuffPlaceholder, CuffType)
    
    init(n: Int) {
        guard n > 1 else { fatalError() }
        self = .number(n)
    }
    
    init(c: CuffPlaceholder) {
        self = .cuff(c, .normal)
    }
    

    init(c: CuffPlaceholder, type: CuffType) {
        self = .cuff(c, type)
        if type == .glideReflected {
            c.twist = c.halfLength
        }
    }

    var cuff: CuffPlaceholder? {
        switch self {
        case .cuff(let c, _):
            return c
        default:
            return nil
        }
    }
    
    var cuffRotation: CuffRotation {
        switch  self {
        case number(let n):
            return CuffRotation.rotation(n)
        default:
            return CuffRotation.cuff(self.cuff!.halfLength)
        }
    }
    
    func enterPantsCuff(pants pants: [Pants], index: [Int]) {
        var pants = pants
        var index = index
        switch self {
        case .cuff(let c, let type):
            switch type {
            case .reflected, .glideReflected:
                // We're omitting some error correction
                if pants.count == 1 {
                    pants.append(pants[0])
                    index.append(index[0])
                }
                c.pantsCuffArrays[0] = [0, 1].map() {PantsCuff(pants: pants[$0], index: index[$0]) }
            case .normal:
                for i in 0..<pants.count {
                    c.pantsCuffArrays[i].append(PantsCuff(pants: pants[i], index: index[i]))
                }
            case .folded:
                for i in 0..<pants.count {
                    c.pantsCuffArrays[i].append(PantsCuff(pants: pants[i], index: index[i]))
                    c.pantsCuffArrays[i].append(PantsCuff(pants: pants[i], index: index[i]))
                }
            }
        default:
            break
        }
    }
    
}

enum PantsPlaceholderType {
    /// With no associated reflections
    case whole
    
    /// With the reflection line bisecting all three cuffs
    case threeZeroHalf
    
    /// With a reflection line bisecting one cuff and interchanging the other two
    case oneOneHalf
}

class PantsPlaceholder {
    
    var cuffArray: [NumberCuff]
    
    var type: PantsPlaceholderType
    
    var pants: [Pants] = []
    
    var hexagon: Hexagon {
        return pants[0].hexagons[0]
    }
    
    var shadowHexagon: Hexagon {
        switch type {
        case .whole:
            return pants[1].hexagons[0]
        case .threeZeroHalf:
            return pants[0].hexagons[1]
        case .oneOneHalf:
            return pants[0].hexagons[0]
        }
    }
    
    var shadowHexagonIndex: Int {
        switch type {
        case .oneOneHalf:
            return 0
        case .threeZeroHalf:
            return 4
        case .whole:
            return 4
        }
    }
    
    convenience init(cuffArray: [NumberCuff]) {
        self.init(cuffArray: cuffArray, type: PantsPlaceholderType.whole)
    }
    
    convenience init(halfCuff: NumberCuff, wholeCuff: NumberCuff) {
        self.init(cuffArray: [halfCuff, wholeCuff], type: PantsPlaceholderType.oneOneHalf)
    }
    
    init(cuffArray: [NumberCuff], type: PantsPlaceholderType) {
        self.cuffArray = cuffArray
        self.type = type
        makePants()
    }
    
    func makePants() {
        switch type {
        case .threeZeroHalf:
            pants = [Pants(cuffHalfLengths: cuffArray.map() {$0.cuffRotation})]
            for cuffIndex in 0..<3 {
                cuffArray[cuffIndex].enterPantsCuff(pants: pants, index: [cuffIndex])
            }
        case .whole:
            let cuffRotations = cuffArray.map() {$0.cuffRotation}
            let p0 = Pants(cuffHalfLengths: cuffRotations)
            let p1 = Pants(cuffHalfLengths: cuffRotations.reverse())
            pants = [p0, p1]
            for cuffIndex in 0..<3 {
                cuffArray[cuffIndex].enterPantsCuff(pants: [p0, p1], index: [cuffIndex, 2-cuffIndex])
            }
        case .oneOneHalf:
            pants = [Pants(cuffHalfLengths: [cuffArray[0].cuffRotation, cuffArray[1].cuffRotation, cuffArray[1].cuffRotation])]
            cuffArray[0].enterPantsCuff(pants: pants, index: [0])
            cuffArray[1].enterPantsCuff(pants: [pants[0], pants[0]], index: [1, 2])
        }
    }
    
    var hasReflection: Bool {
        switch type {
        case .oneOneHalf, .threeZeroHalf:
            return true
        case .whole:
            var result = false
            for i in 0...2 {
                if case let NumberCuff.cuff(_, cuffType) = cuffArray[i] {
                    if cuffType == CuffType.reflected || cuffType == CuffType.glideReflected {
                        result = true
                    }
                }
            }
            return result
        }
    }
    

}

// At some point we should check that we have a valid pants, with 1/p + 1/q + 1/r < 1 (and actual cuffs count as infinity)
func surfaceFromPlaceholders(pantsPlaceholders: [PantsPlaceholder], cuffPlaceholders: [CuffPlaceholder]) -> Surface {
    let hasReflection = pantsPlaceholders.reduce(false, combine: {$0 || $1.hasReflection})
    var pantsArray: [Pants]
    var cuffArray: [Cuff]
    if hasReflection {
        pantsArray = pantsPlaceholders.flatMap({$0.pants})
        cuffArray = cuffPlaceholders.flatMap({$0.cuffArray})
    } else {
        pantsArray = pantsPlaceholders.map({$0.pants[0]})
        cuffArray = cuffPlaceholders.map({$0.cuffArray[0]})
    }
    let s = Surface(pantsArray: pantsArray, cuffArray: cuffArray)
    s.baseHexagon = pantsPlaceholders[0].hexagon
    if hasReflection {
        s.shadowHexagon = pantsPlaceholders[0].shadowHexagon
        s.shadowHexagonIndex = pantsPlaceholders[0].shadowHexagonIndex
    }
    return s
}

