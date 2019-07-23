//
//  NewPantsMaker.swift
//  CircleLimit
//
//  Created by Kahn on 7/22/19.
//  Copyright © 2019 Jeremy Kahn. All rights reserved.
//

import Foundation

// This time we keep everything as lightweight as possible

enum LightweightPants {
    case p30(cuffs: [LightweightCuff])
    case p03(cuffs: [LightweightCuff])
    case p11(whole: LightweightCuff, half: LightweightCuff)
}

/** Contains just the combinatorial information for a cuff.
 */
/* Involutive means flipped or interchanged
   Flipped means that the two hexagons are flipped while being fixed setwise;
   interchanged means that the two hexagons are interchanged
   FlippedInterchanged is a special kind of unpartnered involutive that's flipped on one side and interchanged on the other.
 */
indirect enum LightweightCuff {
    
    case noninvolutive(subtype: NonInvolutive), flipped(subtype: Involutive), interchanged(subtype: Involutive), flippedInterchangedFolded
    
    enum NonInvolutive {
        case partnered(partner: LightweightCuff?), reflected, glideReflected, folded, conePoint(order: Int)
    }
    
    enum Involutive {
        case partnered(partner: LightweightCuff?), midpointFolded, endpointFolded, conePoint(order: Int)
    }
    
    var partner: LightweightCuff? {
        switch self {
        case .noninvolutive(subtype: let subtype):
            switch subtype {
            case .partnered(partner: let partner):
                return partner
            default: return nil
            }
        case .flipped(subtype: let subtype), .interchanged(subtype: let subtype):
            switch subtype {
            case .partnered(partner: let partner):
                return partner
            default: return nil
           }
        default:
            return nil
        }
    }
}

class LightweightSurface {
    
    enum Context {
        case noninvolutive, flipped, interchanged
    }
    
    var cuffTable: [Character: LightweightCuff] = [:]
    
    var pantsArray: [LightweightPants] = []
    
    static let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    static let numbers = "123456789"
    
    func parseNonInvolutiveCuff(cuffCode: Character) throws -> LightweightCuff {
        var subType: LightweightCuff.NonInvolutive
        var mustUpdateTable = false
        switch cuffCode {
        case "*", "|": subType = .reflected
        case "$": subType = .glideReflected
        case "^", ":": subType = .folded
        default:
            if LightweightSurface.letters.contains(cuffCode) {
                if let cuffPlaceholder=cuffTable[cuffCode] {
                    subType = .partnered(partner: cuffPlaceholder)
                    cuffTable.removeValue(forKey: cuffCode)
                } else {
                    subType = .partnered(partner: nil)
                    mustUpdateTable = true
                }
            } else if let d = Int(String(cuffCode)) {
                subType = .conePoint(order: d)
            } else {
                throw PantsCodeError.badCharacter(cuffCode)
            }
        }
        let cuff = LightweightCuff.noninvolutive(subtype: subType)
        if mustUpdateTable {
            cuffTable[cuffCode] = cuff
        }
        return cuff
    }
    
    func parseInvolutiveCuff(cuffCode: Character, context: Context) throws -> LightweightCuff {
        var subType: LightweightCuff.Involutive
        var mustUpdateTable = false
        switch cuffCode {
        case "^", ":": subType = .endpointFolded
        case "?": subType = .midpointFolded
        default:
            if LightweightSurface.letters.contains(cuffCode) {
                if let cuffPlaceholder=cuffTable[cuffCode] {
                    subType = .partnered(partner: cuffPlaceholder)
                    cuffTable.removeValue(forKey: cuffCode)
                } else {
                    subType = .partnered(partner: nil)
                    mustUpdateTable = true
                }
            } else if let d = Int(String(cuffCode)) {
                subType = .conePoint(order: d)
            } else {
                throw PantsCodeError.badCharacter(cuffCode)
            }
        }
        var cuff: LightweightCuff
        switch context {
        case .flipped: cuff = .flipped(subtype: subType)
        case .interchanged: cuff = .interchanged(subtype: subType)
        default:
            throw PantsCodeError.badCharacter(cuffCode)
        }
        if mustUpdateTable {
            cuffTable[cuffCode] = cuff
        }
        return cuff
    }
    
    init(_ code:String) throws {
        let pantsCodes = code.components(separatedBy: " ")
        for pantsCode in pantsCodes {
            var pants: LightweightPants
            var pantsType: PantsPlaceholderType
            var pantsData: String
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
                var cuffs: [LightweightCuff] = []
                for cuffCode in pantsData {
                    try cuffs.append(parseNonInvolutiveCuff(cuffCode: cuffCode))
                }
                pants = .p30(cuffs: cuffs)
            case .threeZeroHalf:
                var cuffs: [LightweightCuff] = []
                for cuffCode in pantsData {
                    try cuffs.append(parseInvolutiveCuff(cuffCode: cuffCode, context: .interchanged))
                }
                pants = .p03(cuffs: cuffs)
            case .oneOneHalf:
                let wholeData = pantsData.atNumericalIndex(n: 0)
                let wholeCuff = try parseNonInvolutiveCuff(cuffCode: wholeData)
                let halfData = pantsData.atNumericalIndex(n: 1)
                let halfCuff = try parseInvolutiveCuff(cuffCode: halfData, context: .flipped)
                pants = .p11(whole: wholeCuff, half: halfCuff)
            }
            pantsArray.append(pants)
        }
    }

}


