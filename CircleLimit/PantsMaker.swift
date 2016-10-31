//
//  PantsMaker.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 8/26/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

/// Keeps track of two NumberCuff's that in turn point back here, so that they can find each other
class CuffPlaceholder: Hashable {
    
    var type: CuffType
    
    var pantsCuffArrays: [[PantsCuff]] = [[], []]
    
    var halfLength: Double
    
    var twist: Double
    
    init(halfLength: Double, twist: Double, type: CuffType) {
        self.halfLength = halfLength
        self.type = type
        switch type {
        case .folded, .normal:
            self.twist = twist
        case .reflected, .bisected:
            self.twist = 0.0
        case .glideReflected, .bisectedReflected:
            self.twist = halfLength
        case .halfWhole:
            self.twist = halfLength/2
        }
        
    }
    
    // Should be used for any cuff where there's any kind of reflection
    convenience init(halfLength: Double, type: CuffType) {
        self.init(halfLength: halfLength, twist: 0.0, type:type)
    }
    
    convenience init(halfLength: Double, twist: Double)  {
        self.init(halfLength: halfLength, twist: twist, type: CuffType.normal)
    }
    
    convenience init(halfLength: Double) {
        self.init(halfLength: halfLength, twist: 0.0, type: .normal)
    }

    /// This should be called only once!
    var cuffArray: [Cuff] {
        let pantsCuffArray0 = pantsCuffArrays[0]
        let pantsCuffArray1 = pantsCuffArrays[1]
        var result: [Cuff] = [Cuff(pantsCuff0: pantsCuffArray0[0], pantsCuff1: pantsCuffArray0[1], twist: twist)]
        if pantsCuffArrays[1].count > 0 {
            result.append(Cuff(pantsCuff0: pantsCuffArray1[0], pantsCuff1: pantsCuffArray1[1], twist: -twist))
            for i in 0...1 {
                result[i].info = CuffInfo.normalWithPartner(result[1-i])
            }
        } else {
            switch type {
            case .normal, .folded:
                result[0].info = .normal
            case .reflected, .bisected:
                result[0].info = .zeroTwist
            case .glideReflected, .bisectedReflected:
                result[0].info = .halfTwist
            case .halfWhole:
                result[0].info = .quarterTwist
            }
        }
        return result
    }
    
    var nc: NumberCuff {
        return NumberCuff(c: self)
    }
    
    var hashValue: Int = 0
}


func==(lhs: CuffPlaceholder, rhs: CuffPlaceholder) -> Bool {
    return lhs === rhs
}

enum CuffType {
    case normal, folded, reflected, glideReflected, bisected, bisectedReflected, halfWhole
    
    var defaultCuff: CuffPlaceholder {
        switch self {
        case .normal:
            return CuffPlaceholder(halfLength: 1.0, twist: 0.1, type: self)
        case .folded:
            return CuffPlaceholder(halfLength: 1.0, twist: 1.1, type: self)
        case .reflected, .glideReflected, .bisected, .bisectedReflected, .halfWhole:
            return CuffPlaceholder(halfLength: 1.0, type: self)
        }
    }
    
    var numberCuff: NumberCuff {
        return NumberCuff(c: defaultCuff)
    }
    
    var bisected: Bool {
        switch self {
        case .bisected, .bisectedReflected:
            return true
        default:
            return false
        }
    }

    
}


/// A number or a cuff: the number is at least 2, and the cuff can find its match
enum NumberCuff {
    
    case number(Int)
    
    case cuff(CuffPlaceholder)
    
    init(n: Int) {
        if n == -22 {
            self = CuffType.bisectedReflected.numberCuff
            return
        }
        guard n > 1 else { fatalError() }
        self = .number(n)
    }
    
    init(c: CuffPlaceholder) {
        self = .cuff(c)
    }
    

    var cuff: CuffPlaceholder? {
        switch self {
        case .cuff(let c):
            return c
        default:
            return nil
        }
    }
    
    var cuffRotation: CuffRotation {
        switch  self {
        case .number(let n):
            return CuffRotation.rotation(n)
        default:
            return CuffRotation.cuff(self.cuff!.halfLength)
        }
    }
    
    func enterPantsCuff(pants: [Pants], index: [Int]) {
        var pants = pants
        var index = index
        switch self {
        case .cuff(let c):
            switch c.type {
            case .reflected, .glideReflected:
                // We're omitting some error correction
                if pants.count == 1 {
                    pants.append(pants[0])
                    index.append(index[0])
                }
                c.pantsCuffArrays[0] = [0, 1].map() {PantsCuff(pants: pants[$0], index: index[$0]) }
            case .normal, .bisected, .halfWhole:
                for i in 0..<pants.count {
                    c.pantsCuffArrays[i].append(PantsCuff(pants: pants[i], index: index[i]))
                }
            case .folded, .bisectedReflected:
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

// TODO: Check the the right type of Cuffs are being entered (bisected or not)
class PantsPlaceholder {
    
    static let pantsColorList = [UIColor.green, UIColor.gray, UIColor.orange, UIColor.yellow, UIColor.purple, UIColor.brown]
    
    static var pantsColorIndex = 0
    
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
            let p1 = Pants(cuffHalfLengths: cuffRotations.reversed())
            pants = [p0, p1]
            for cuffIndex in 0..<3 {
                cuffArray[cuffIndex].enterPantsCuff(pants: [p0, p1], index: [cuffIndex, 2-cuffIndex])
            }
        case .oneOneHalf:
            pants = [Pants(cuffHalfLengths: [cuffArray[0].cuffRotation, cuffArray[1].cuffRotation, cuffArray[1].cuffRotation])]
            cuffArray[0].enterPantsCuff(pants: pants, index: [0])
            cuffArray[1].enterPantsCuff(pants: [pants[0], pants[0]], index: [1, 2])
        }
        let color = PantsPlaceholder.pantsColorList[PantsPlaceholder.pantsColorIndex]
        for p in pants {
            p.color = color
        }
        PantsPlaceholder.pantsColorIndex += 1
        if PantsPlaceholder.pantsColorIndex >= PantsPlaceholder.pantsColorList.count {
            PantsPlaceholder.pantsColorIndex = 0
        }
    }
    
    var hasReflection: Bool {
        switch type {
        case .oneOneHalf, .threeZeroHalf:
            return true
        case .whole:
            var result = false
            for i in 0...2 {
                if case let NumberCuff.cuff(c) = cuffArray[i] {
                    if c.type == CuffType.reflected || c.type == CuffType.glideReflected {
                        result = true
                    }
                }
            }
            return result
        }
    }
    

}

// At some point we should check that we have a valid pants, with 1/p + 1/q + 1/r < 1 (and actual cuffs count as infinity)
func surfaceFromPlaceholders(_ pantsPlaceholders: [PantsPlaceholder]) -> Surface {

    var cpSet = Set<CuffPlaceholder>()
    for p in pantsPlaceholders {
        for nc in p.cuffArray {
            if let c = nc.cuff {
                cpSet.insert(c)
            }
        }
    }
    let cuffPlaceholders = Array(cpSet)
    
    let hasReflection = pantsPlaceholders.reduce(false, {$0 || $1.hasReflection})
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

