
//
//  ConwayParser.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 10/19/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

// TODO: Get the cone points in the right cyclic order on the boundaries
/// Represents all the possible features that might be added to a surface
enum Feature {
    
    case twoTwo
    case handle
    case conePoint(Int)
    case reflection([Int])
    case glide
    case hole
    
    /// The NumberCuff for the feature, along with internal pants and cuffs, including the cuff for the feature
    var numberCuff: (NumberCuff, [PantsPlaceholder]) {
        switch self {
        case .conePoint(let n):
            return (NumberCuff(n: n), [])
        case .glide:
            return (CuffType.glideReflected.numberCuff, [])
        case .twoTwo:
            return (CuffType.folded.numberCuff, [])
        case .handle:
            let nc = CuffType.normal.numberCuff
            let cc = CuffPlaceholder(halfLength: 1.0, twist: 0.1)
             let p = PantsPlaceholder(cuffArray: [nc, NumberCuff(c: cc), NumberCuff(c: cc)])
            return (nc, [p])
        case .hole:
            return (CuffType.normal.numberCuff, [])
        case .reflection(let list):
            switch list.count {
            case 0:
                return (CuffType.reflected.numberCuff, [])
            case 1:
                let nc = CuffType.normal.numberCuff
                let p = PantsPlaceholder(halfCuff: NumberCuff(n: list[0], halfWhole: true), wholeCuff: nc)
                return (nc, [p])
            default:
                let nc = CuffType.normal.numberCuff
                let nc2 = CuffType.halfWhole.numberCuff
                let p = PantsPlaceholder(halfCuff: nc2, wholeCuff: nc)
                var pants = halfPants(halfCuff: nc2)!
                pants.append(p)
                return (nc, pants)
            }
        }
    }
    
    /// The list of pants to add to a cuff to produce the given feature
    func pantsFromCuff(nc: NumberCuff) -> [PantsPlaceholder]? {
        switch self {
        case .handle:
            let cc = CuffPlaceholder(halfLength: 1.0, twist: 0.1)
            let p = PantsPlaceholder(cuffArray: [nc, NumberCuff(c: cc), NumberCuff(c: cc)])
            return [p]
        case .hole:
            return []
        case .reflection(let list):
            guard list.count >= 1 else { return nil }
            if list.count == 1 {
                let p = PantsPlaceholder(halfCuff: NumberCuff(n: list[0], halfWhole: true), wholeCuff: nc)
                return [p]
            }
            let nc2 = CuffType.halfWhole.numberCuff
            var pants = halfPants(halfCuff: nc2)!
            let p = PantsPlaceholder(halfCuff: nc2, wholeCuff: nc)
            pants.append(p)
            return pants
        default:
            return nil
        }
    }
    
    var canMakePantsFromCuff: Bool {
        switch  self {
        case .hole:
            return true
        case .handle:
            return true
        case .reflection(let list):
            return list.count >= 1
        default:
            return false
        }
    }
    
    // TODO: Should we add the case .hole?
    func halfPants(halfCuff: NumberCuff) -> [PantsPlaceholder]? {
        guard  case let Feature.reflection(list) = self else {
            return nil
        }
        guard list.count >= 2 else { return nil }
        var pants: [PantsPlaceholder] = []
        var oldNC = halfCuff
        for i in 0..<list.count - 2 {
            let newNC = CuffType.bisected.numberCuff
            let pp = PantsPlaceholder(cuffArray: [oldNC, NumberCuff(n: list[i]), newNC], type: .threeZeroHalf)
            oldNC = newNC
            pants.append(pp)
        }
        let ppp = PantsPlaceholder(cuffArray: [oldNC, NumberCuff(n: list[list.count-1]), NumberCuff(n: list[list.count-2])], type: .threeZeroHalf)
        pants.append(ppp)
        return pants
    }
    
    /// The contribution of the feature to the Euler characteristic
    var value: Double {
        switch self {
        case .conePoint(let n):
            return 1/Double(n) - 1.0
        case .glide:
            return -1.0
        case .handle:
            return -2.0
        case .hole:
            return -1.0
        case .reflection(let list):
            var m = -1.0
            for n in list {
                m += (1/Double(n) - 1.0)/2
            }
            return m
        case .twoTwo:
            return -1.0
        }
        
    }
    
}

class Tokenizer {
    
    var result: [Feature] = []
    
    var haveTwo = false
    var makingStar = false
    var starList: [Int] = []
    
    func wrapItUp() {
        if makingStar {
            if haveTwo {
                starList.append(2)
                haveTwo = false
            }
            result.append(Feature.reflection(starList))
            makingStar = false
            starList = []
        } else {
            if haveTwo {
                result.append(Feature.conePoint(2))
                haveTwo = false
            }
        }
    }
    
    func tokens(_ conway: String) throws -> [Feature]  {
        
        for c in conway {
            switch c {
            case "o":
                result.append(Feature.handle)
            case "c":
                result.append(Feature.hole)
            case "2":
                if !haveTwo {
                    haveTwo = true
                } else {
                    haveTwo = false
                    if !makingStar {
                        result.append(Feature.twoTwo)
                    } else {
                        starList.append(-22)
                    }
                }
            case "3", "4", "5", "6", "7", "8", "9":
                if !makingStar {
                    if haveTwo {
                        result.append(Feature.conePoint(2))
                        haveTwo = false
                    }
                    result.append(Feature.conePoint(c.int!))
                } else {
                    if haveTwo {
                        starList.append(2)
                        haveTwo = false
                    }
                    starList.append(c.int!)
                }
            case "*":
                wrapItUp()
                makingStar = true
            case "x":
                wrapItUp()
                result.append(Feature.glide)
            case "\n", " ", "\t":
                break
            default:
                throw BadConway.badParse
            }
        }
        
        wrapItUp()
        
        return result
    }
    
}


enum BadConway: Error {
    
    case badParse
    case nonNegativeEuler
    
}

func placeholders(conway: String) throws -> [PantsPlaceholder]  {
    
    let features = try Tokenizer().tokens(conway)
    let euler = 2.0 + features.sum({$0.value})
    guard euler < -0.0001 else {
        throw BadConway.nonNegativeEuler
    }
    var pants: [PantsPlaceholder] = []
    
    PantsPlaceholder.pantsColorIndex = 0
    
    switch features.count {
        
    case 0:
        throw BadConway.nonNegativeEuler
        
    case 1:
        guard case var Feature.reflection(list) = features[0] else {
            throw BadConway.nonNegativeEuler
        }
        switch list.count {
        case 0, 1, 2:
            throw BadConway.nonNegativeEuler
        case 3:
            var ncs: [NumberCuff] = []
             for n in list {
                let nc = NumberCuff(n: n)
                ncs.append(nc)
            }
            let p = PantsPlaceholder(cuffArray: ncs, type: PantsPlaceholderType.threeZeroHalf)
            pants = [p]
         default:
            let nc0 = NumberCuff(n: list.popLast()!)
            let nc1 = NumberCuff(n: list.popLast()!)
            let nc = CuffType.bisected.numberCuff
            let p = PantsPlaceholder(cuffArray: [nc, nc0, nc1], type: PantsPlaceholderType.threeZeroHalf)
            let newFeature = Feature.reflection(list)
            let pp = newFeature.halfPants(halfCuff: nc)!
            pants = [p] + pp
        }
        
        
    case 2:
        var D:Feature
        var s:Feature
        if features[0].canMakePantsFromCuff {
            D = features[0]
            s = features[1]
        } else if features[1].canMakePantsFromCuff {
            s = features[0]
            D = features[1]
        } else {
            fatalError()
        }
        switch (s, D) {
        case (.conePoint(2), .reflection):
            pants = D.halfPants(halfCuff: CuffType.bisectedReflectedHalfWhole.numberCuff)!
        default:
            let (nc, p) = s.numberCuff
            let pp = D.pantsFromCuff(nc: nc)!
            pants = p + pp
        }

    case 3:
        var numberCuffs: [NumberCuff] = []
         for feature in features {
            let (nc, newPants) = feature.numberCuff
            numberCuffs.append(nc)
            pants += newPants
        }
        let p = PantsPlaceholder(cuffArray: numberCuffs)
        pants.append(p)
        
    default:
        var oldNumberCuff = CuffType.normal.numberCuff
        let (nc0, p0) = features[0].numberCuff
        let (nc1, p1) = features[1].numberCuff
        let pStart = PantsPlaceholder(cuffArray: [nc0, nc1, oldNumberCuff])
        pants = p0 + p1 + [pStart]
        for i in 2..<features.count-2 {
            let newNumberCuff = CuffType.normal.numberCuff
            let (nc, p) = features[i].numberCuff
            let pp = PantsPlaceholder(cuffArray: [oldNumberCuff, newNumberCuff, nc])
            pants += [pp] + p
            oldNumberCuff = newNumberCuff
        }
        let (nc2, p2) = features[features.count - 2].numberCuff
        let (nc3, p3) = features[features.count - 3].numberCuff
        let pEnd = PantsPlaceholder(cuffArray: [nc2, nc3, oldNumberCuff])
        pants += p2 + p3 + [pEnd]
    }
    
    return pants
    
}

