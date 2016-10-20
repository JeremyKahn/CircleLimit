//
//  ConwayParser.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 10/19/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

// TODO: Get the cone points in the right cyclic order on the boundaries

enum Feature {
    
    case twoTwo
    case handle
    case conePoint(Int)
    case reflection([Int])
    case glide
    
    /// The NumberCuff for the feature, along with internal pants and cuffs
    var numberCuff: (NumberCuff, [PantsPlaceholder], [CuffPlaceholder]) {
        switch self {
        case .conePoint(let n):
            return (NumberCuff(n: n), [], [])
        case .glide:
            return (CuffType.glideReflected.numberCuff, [], [])
        case .twoTwo:
            return (CuffType.folded.numberCuff, [], [])
        case .handle:
            let cc = CuffPlaceholder(halfLength: 1.0, twist: 0.1)
            let nc = CuffType.normal.numberCuff
            let p = PantsPlaceholder(cuffArray: [nc, NumberCuff(c: cc), NumberCuff(c: cc)])
            return (nc, [p], [cc])
        case .reflection(let list):
            switch list.count {
            case 0:
                return (CuffType.reflected.numberCuff, [], [])
            case 1:
                let nc = CuffType.normal.numberCuff
                let p = PantsPlaceholder(halfCuff: NumberCuff(n: list[0]), wholeCuff: nc)
                return (nc, [p], [])
            default:
                let nc = CuffType.normal.numberCuff
                let c = CuffPlaceholder(halfLength: 1.0)
                let nc2 = NumberCuff(c: c)
                let p = PantsPlaceholder(halfCuff: nc2, wholeCuff: nc)
                var (pants, cuffs) = halfPantsAndCuffs(halfCuff: nc2)!
                pants.append(p)
                cuffs.append(c)
                return (nc, pants, cuffs)
            }
        }
    }
    
    func pantsFromCuff(nc: NumberCuff) -> ([PantsPlaceholder], [CuffPlaceholder])? {
        switch self {
        case .handle:
            let cc = CuffPlaceholder(halfLength: 1.0, twist: 0.1)
            let p = PantsPlaceholder(cuffArray: [nc, NumberCuff(c: cc), NumberCuff(c: cc)])
            return ([p], [cc])
        case .reflection(let list):
            guard list.count >= 1 else { return nil }
            if list.count == 1 {
                let p = PantsPlaceholder(halfCuff: NumberCuff(n: list[0]), wholeCuff: nc)
                return ([p], [])
            }
            let c = CuffPlaceholder(halfLength: 1.0)
            let nc2 = NumberCuff(c: c)
            var (pants, cuffs) = halfPantsAndCuffs(halfCuff: nc2)!
            let p = PantsPlaceholder(halfCuff: nc2, wholeCuff: nc)
            pants.append(p)
            return (pants, cuffs)
         default:
            return nil
        }
    }
    
    var canMakePantsFromCuff: Bool {
        switch  self {
        case .handle:
            return true
        case .reflection(let list):
            return list.count >= 1
        default:
            return false
        }
    }
    
    func halfPantsAndCuffs(halfCuff: NumberCuff) -> ([PantsPlaceholder], [CuffPlaceholder])? {
        guard  case let Feature.reflection(list) = self else {
            return nil
        }
        guard list.count >= 2 else { return nil }
        var cuffs: [CuffPlaceholder] = []
        var pants: [PantsPlaceholder] = []
        var oldNC = halfCuff
        for i in 0..<list.count - 2 {
            let cc = CuffPlaceholder(halfLength: 1.0)
            let newNC = NumberCuff(c: cc)
            let pp = PantsPlaceholder(cuffArray: [oldNC, NumberCuff(n: list[i]), newNC], type: .threeZeroHalf)
            oldNC = newNC
            cuffs.append(cc)
            pants.append(pp)
        }
        let ppp = PantsPlaceholder(cuffArray: [oldNC, NumberCuff(n: list[list.count-1]), NumberCuff(n: list[list.count-2])], type: .threeZeroHalf)
        pants.append(ppp)
        return (pants, cuffs)
     }

}



func tokens(_ conway: String) -> [Feature] {
    
    var result: [Feature] = []
    
    var haveTwo = false
    var makingStar = false
    var starList: [Int] = []
    
    for c in conway.characters {
        switch c {
        case "o":
            result.append(Feature.handle)
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
            if !makingStar {
                makingStar = true
            } else {
                result.append((Feature.reflection(starList)))
                starList = []
            }
        case "x":
            if makingStar {
                result.append(Feature.reflection(starList))
                starList = []
                makingStar = false
            }
            result.append(Feature.glide)
        default:
            fatalError()
        }
    }
    
    return result
}



func placeholders(conway: String) -> ([PantsPlaceholder], [CuffPlaceholder]) {
    
    let features = tokens(conway)
    var pants: [PantsPlaceholder]
    var cuffs: [CuffPlaceholder]
    
    switch features.count {
        
    case 0:
        fatalError()
        
    case 1:
        guard case var Feature.reflection(list) = features[0] else {
            fatalError()
        }
        switch list.count {
        case 0, 1, 2:
            fatalError()
        case 3:
            var ncs: [NumberCuff] = []
            for n in list {
                ncs.append(NumberCuff(n: n))
            }
            let p = PantsPlaceholder(cuffArray: ncs, type: PantsPlaceholderType.threeZeroHalf)
            pants = [p]
            cuffs = []
        default:
            let nc0 = NumberCuff(n: list.popLast()!)
            let nc1 = NumberCuff(n: list.popLast()!)
            let c = CuffPlaceholder(halfLength: 1.0)
            let nc = NumberCuff(c: c)
            let p = PantsPlaceholder(cuffArray: [nc, nc0, nc1], type: PantsPlaceholderType.threeZeroHalf)
            let newFeature = Feature.reflection(list)
            let (pp, cc) = newFeature.halfPantsAndCuffs(halfCuff: nc)!
            pants = [p] + pp
            cuffs = [c] + cc
        }
        
        
    case 2:
        if features[0].canMakePantsFromCuff {
            let (nc, p, c) = features[1].numberCuff
            let (pp, cc) = features[0].pantsFromCuff(nc: nc)!
            pants = p + pp
            cuffs = c + [nc.cuff!] + cc
        } else if features[1].canMakePantsFromCuff {
            let (nc, p, c) = features[0].numberCuff
            let (pp, cc) = features[1].pantsFromCuff(nc: nc)!
            pants = p + pp
            cuffs = c + [nc.cuff!] + cc
        } else {
            fatalError()
        }
 
    case 3:
        var numberCuffs: [NumberCuff] = []
        pants = []
        cuffs = []
        for feature in features {
            let (nc, newPants, newCuffs) = feature.numberCuff
            numberCuffs.append(nc)
            pants += newPants
            cuffs += newCuffs
        }
        let p = PantsPlaceholder(cuffArray: numberCuffs)
        pants.append(p)
    
    default:
        var oldNumberCuff = CuffType.normal.numberCuff
        let (nc0, p0, c0) = features[0].numberCuff
        let (nc1, p1, c1) = features[1].numberCuff
        let pStart = PantsPlaceholder(cuffArray: [nc0, nc1, oldNumberCuff])
        pants = p0 + p1 + [pStart]
        cuffs = c0 + c1 + [oldNumberCuff.cuff!]
        for i in 2..<features.count-2 {
            let newNumberCuff = CuffType.normal.numberCuff
            let (nc, p, c) = features[i].numberCuff
            let pp = PantsPlaceholder(cuffArray: [oldNumberCuff, newNumberCuff, nc])
            pants += [pp] + p
            cuffs += [newNumberCuff.cuff!] + [nc.cuff!] + c
            oldNumberCuff = newNumberCuff
        }
        let (nc2, p2, c2) = features[features.count - 2].numberCuff
        let (nc3, p3, c3) = features[features.count - 3].numberCuff
        let pEnd = PantsPlaceholder(cuffArray: [nc2, nc3, oldNumberCuff])
        pants += p2 + p3 + [pEnd]
        cuffs += c2 + c3
    }
    
    return (pants, cuffs)
    
}
