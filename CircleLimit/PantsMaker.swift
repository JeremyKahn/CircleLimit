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
    
    var nextIndex = 0
    
    var cuffPlaceHolderArray = Array(count: 2, repeatedValue: NumberCuff.none)
    
    var pantsCuffArray = Array<PantsCuff?>(count: 2, repeatedValue: nil)
    
    var complete: Bool {
        return pantsCuffArray.reduce(true, combine: {$0 && $1 != nil})
    }
    
}

// TODO: Add in lengths and twists, with defaults of acosh(2.0) and 0
/// A number or a cuff: the number is at least 2, and the cuff can find its match
enum NumberCuff {
    
    case none
    
    /** _
     - parameters: The rotation number
     */
    case number(Int)
    
    
    case cuff(CuffPlaceholder, Int)
    
    init(n: Int) {
        guard n > 1 else {
            self = .none
            return
        }
        self = .number(n)
    }
    
    init(p: CuffPlaceholder) {
        guard p.nextIndex < 1 else {
            self = .none
            return
        }
        self = .cuff(p, p.nextIndex)
        p.cuffPlaceHolderArray[p.nextIndex] = self
        p.nextIndex += 1
    }
    
    var matchingCuff: NumberCuff {
        switch self {
        case cuff(let p, let i):
            return p.cuffPlaceHolderArray[1 - i]
        default:
            return .none
        }
    }
        
}

class PantsPlaceholder {
    
    var numberCuffArray = Array(count: 3, repeatedValue: NumberCuff.none)
    
}

// At some point we should check that we have a valid pants, with 1/p + 1/q + 1/r < 1 (and actual cuffs count as infinity)
func pantsAndCuffArrayFromPlaceholders(placeholders: [PantsPlaceholder]) -> ([Pants], [Cuff]) {
    var pantsArray: [Pants] = []
    var cuffArray: [Cuff] = []
    for p in placeholders {
        let cuffs = p.numberCuffArray.map() {
            (nc: NumberCuff) -> CuffRotation in
            switch nc {
            case .none:
                fatalError()
            case .number(let n):
                return CuffRotation.rotation(n)
            case .cuff:
                return CuffRotation.cuff(0.3)
            }
        }
        let pants = Pants(cuffHalfLengths: cuffs)
        for cuffIndex in 0..<3 {
            let c = p.numberCuffArray[cuffIndex]
            switch c {
            // cph is the CuffPlaceHolder
            case .cuff(let cph, let i):
                cph.pantsCuffArray[i] = PantsCuff(pants: pants, index: cuffIndex)
                if cph.complete {
                    let pantsCuffArray = cph.pantsCuffArray
                    cuffArray.append(Cuff(pantsCuff0: pantsCuffArray[0]!, pantsCuff1: pantsCuffArray[1]!, twist: 0.0))
                }
            default:
                break
            }
        }
        pantsArray.append(pants)
    }
    return (pantsArray, cuffArray)
}

