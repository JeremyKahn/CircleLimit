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
        case .reflected, .bisected, .bisectedReflectedHalfWhole:
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
            case .reflected, .bisected, .bisectedReflectedHalfWhole:
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

/* There are five kinds of "whole" cuffs: the oriented ones, namely normal, a cone point, or "folded" (22),
 and the non-oriented ones, namely reflected and glide reflected.
 The new notation for the "half" cuffs uses 'r' for preserving the hexagons, 'R' for interchaging them, 'pi' for 180 degree rotation, and '1' for reflection through the cuff.
 Then we have <r>, <r, 1>, and <r, R1> for one type of half cuffs, and <R>, <R, 1>, and <R, r1> for the other.
 The only ones we really need are <r>, <r, 1>, <R>, and <R, 1>, so perhaps those are the four that were defined?
 It seems like "halfWhole" comes from the 03 pants and is hence R, and "bisected" from the 11 and is hence r,
 and then "bisectedReflected" is <r, 1> and bisectedReflectedHalfWhole is <R, 1>?
 */

enum CuffType {
    case normal, folded, reflected, glideReflected, bisected, bisectedReflected, halfWhole, bisectedReflectedHalfWhole
    
    var defaultCuff: CuffPlaceholder {
        switch self {
        case .normal:
            return CuffPlaceholder(halfLength: 1.0, twist: 0.1, type: self)
        case .folded:
            return CuffPlaceholder(halfLength: 1.0, twist: 1.1, type: self)
        case .reflected, .glideReflected, .bisected, .bisectedReflected, .halfWhole, .bisectedReflectedHalfWhole:
            return CuffPlaceholder(halfLength: 1.0, type: self)
        }
    }
    
    var numberCuff: NumberCuff {
        return NumberCuff(c: defaultCuff)
    }
    
    var bisected: Bool {
        switch self {
        case .bisected, .bisectedReflected, .bisectedReflectedHalfWhole:
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
    
    init(n: Int, halfWhole: Bool) {
        if n == -22 && halfWhole {
            self = CuffType.bisectedReflectedHalfWhole.numberCuff
        } else {
            self = NumberCuff(n: n)
        }
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
            case .folded, .bisectedReflected, .bisectedReflectedHalfWhole:
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
    
    static let typeFromCode = ["30": PantsPlaceholderType.whole, "03": PantsPlaceholderType.oneOneHalf, "11":PantsPlaceholderType.oneOneHalf]
}

enum PantsCodeError: Error {
    case badCharacter(Character)
}


// TODO: Check the the right type of Cuffs are being entered (bisected or not)
class PantsPlaceholder {
    
    static let pantsColorList = [UIColor.green, UIColor.orange, UIColor.yellow, UIColor.purple, UIColor.cyan, UIColor.magenta, UIColor.brown]
    
    static var pantsColorIndex = 0
    
    static func cuffForCode(_ cuffCode: Character, cuffTable: inout [Character: CuffPlaceholder]) throws -> NumberCuff {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var cuff: NumberCuff
        switch cuffCode {
        case "*", "|": cuff = CuffType.reflected.numberCuff
        case "$": cuff = CuffType.glideReflected.numberCuff
        case "^": cuff = CuffType.folded.numberCuff
        default:
            if letters.contains(cuffCode) {
                if let cuffPlaceholder=cuffTable[cuffCode] {
                    cuff = NumberCuff(c: cuffPlaceholder)
                    cuffTable.removeValue(forKey: cuffCode)
                } else {
                    cuff = CuffType.normal.numberCuff
                    cuffTable[cuffCode] = cuff.cuff!
                }
            } else {
                throw PantsCodeError.badCharacter(cuffCode)
            }
        }
        return cuff
    }
    
    static func parsePantsCode(_ code:String) throws -> [PantsPlaceholder] {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var placeholders: [PantsPlaceholder] = []
        var cuffTable: [Character: CuffPlaceholder] = [:]
        let pantsCodes = code.components(separatedBy: " ")
        for pantsCode in pantsCodes {
            var pantsType: PantsPlaceholderType
            var pantsData: String
            var cuffs: [NumberCuff] = []
            if pantsCode.contains("-") {
                let stuff = pantsCode.components(separatedBy: "-")
                pantsType = PantsPlaceholderType.typeFromCode[stuff[0]]!
                pantsData = stuff[1]
            } else {
                pantsType = PantsPlaceholderType.whole
                pantsData = pantsCode
            }
            switch pantsType {
            case .whole:
                for cuffCode in pantsData {
                    try cuffs.append(cuffForCode(cuffCode, cuffTable: &cuffTable))
                }
            case .oneOneHalf:
            let whole = pantsData.atNumericalIndex(n: 0)
            let half = pantsData.atNumericalIndex(n: 1)
            try cuffs.append(cuffForCode(whole, cuffTable: &cuffTable))
            let cuffCode = half
            var cuff: NumberCuff
            switch half {
                // Not clear that these are correct
                case "^": cuff = CuffType.bisectedReflected.numberCuff
                case "?": cuff = CuffType.bisectedReflectedHalfWhole.numberCuff
                default:
                    if letters.contains(cuffCode) {
                        if let cuffPlaceholder=cuffTable[cuffCode] {
                            cuff = NumberCuff(c: cuffPlaceholder)
                            cuffTable.removeValue(forKey: cuffCode)
                        } else {
                            cuff = CuffType.normal.numberCuff
                            cuffTable[cuffCode] = cuff.cuff!
                        }
                    } else {
                        throw PantsCodeError.badCharacter(cuffCode)
                    }
            }
            cuffs.append(cuff)
            case .threeZeroHalf:
                for cuffCode in pantsData {
                    var cuff: NumberCuff
                    switch cuffCode {
                    // No real chance at all that these are correct
                    case "^": cuff = CuffType.bisectedReflectedHalfWhole.numberCuff
                    case "?": cuff = CuffType.bisectedReflectedHalfWhole.numberCuff
                    default:
                    if letters.contains(cuffCode) {
                        if let cuffPlaceholder=cuffTable[cuffCode] {
                            cuff = NumberCuff(c: cuffPlaceholder)
                            cuffTable.removeValue(forKey: cuffCode)
                        } else {
                            cuff = CuffType.normal.numberCuff
                            cuffTable[cuffCode] = cuff.cuff!
                        }
                    } else {
                        throw PantsCodeError.badCharacter(cuffCode)
                    }
                }
                cuffs.append(cuff)
                }
            }
            placeholders.append(PantsPlaceholder(cuffArray: cuffs, type: pantsType))
        }
        return placeholders
    }


    
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
    
    func setUpShadowHexagonsAndIndices() {
        for i in 0..<pants.count {
            for j in 0...1 {
                let ii: Int, jj: Int
                switch type {
                case .whole:
                    ii = 1 - i
                    jj = j
                case .threeZeroHalf:
                    ii = i
                    jj = 1 - j
                case .oneOneHalf:
                    ii = i
                    jj = j
                }
                let h = pants[i].hexagons[j]
                h.shadowHexagon = pants[ii].hexagons[jj]
                h.shadowHexagonIndex = shadowHexagonIndex
            }
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
        s.hasReflection = true
        for pp in pantsPlaceholders {
            pp.setUpShadowHexagonsAndIndices()
        }
    }
    return s
}

