//
//  Cuff.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/25/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

/// A pair of pants, with an identified cuff
struct PantsCuff {
    
    var pants: Pants
    var index: Int
    
    func setLength(_ newLength: Double) {
        pants.cuffHalfLengths[index] = newLength + 0.i
    }
    
}

enum CuffInfo {
    
    case normal
    case normalWithPartner(Cuff)
    case reflected
    case glideReflected
    
}

/// A cuff, with two associated pants
class Cuff {
    
    var info: CuffInfo = .normal
    
    // The point at the middle of the selected cuff segment
    var baseMask: HTrans {
        let pants = pantsCuffs[0]!.pants
        let index = pantsCuffs[0]!.index
        let sideIndex = pants.sideIndexForCuffIndex(index, AndHexagonIndex: 0)
        return pants.baseMask.following(pants.hexagons[0].end[sideIndex])
    }
    
    var guidelineCenterpoint: HTrans {
        let pants = pantsCuffs[0]!.pants
        let sideIndex = pants.sideIndexForCuffIndex(pantsCuffs[0]!.index, AndHexagonIndex: 0)
        return pants.baseMask.appliedTo(pants.hexagons[0].end[sideIndex])
    }
    
    private var signalPartner = true
    
    private var _twist: Double
    
    var twist: Double  {
        set(newTwist) {
            switch info {
            case .normalWithPartner(let partner):
                if signalPartner  {
                    partner.signalPartner = false
                    partner.twist = -twist
                    partner.signalPartner = true
                }
                fallthrough
            case .normal:
                _twist = newTwist
                setUpTwistsAndGroupoidElementsForThisCuff()
            case .glideReflected, .reflected:
                break
            }
        }
        
        get {
            return _twist
        }
    }
    
    // Tells the two pants to set up the groupoid elements between the two pants
    func setUpTwistsAndGroupoidElementsForThisCuff() {
        for i in 0...1 {
            let pantsCuff = pantsCuffs[i]!
            let otherPantsCuff = pantsCuffs[1-i]!
            pantsCuff.pants.adjacenciesAndTwists[pantsCuff.index] = (otherPantsCuff.pants, otherPantsCuff.index, twist)
        }
        for pantsCuff in pantsCuffs {
            pantsCuff!.pants.setUpGroupoidElementToAdjacentPantsForIndex(pantsCuff!.index, updateNeighbor: false)
        }
    }
    
    private var _halfLength: Double
    
    var halfLength: Double {
        return _halfLength
    }
    
    func setHalfLength(_ newLength: Double) {
        _halfLength = newLength
        
        switch info {
        case .normalWithPartner(let partner):
            if signalPartner {
                partner.signalPartner = false
                partner.setHalfLength(newLength)
                partner.signalPartner = true
            }
        case .glideReflected:
            _twist = halfLength
            setUpTwistsAndGroupoidElementsForThisCuff()
        case .reflected, .normal:
            break
        }
        
        for pantsCuff in pantsCuffs {
            pantsCuff?.setLength(halfLength)
        }
    }
    
    var pantsCuffs: [PantsCuff?] = [nil, nil]
    
    var guideline: HDrawable {
        return pantsCuffs[0]!.pants.cuffGuidelines[pantsCuffs[0]!.index]!
    }
    
    var transformedGuideline: HDrawable {
        return guideline.transformedBy(pantsCuffs[0]!.pants.baseMask)
    }
    
    convenience init(pantsCuff0: PantsCuff, pantsCuff1: PantsCuff, twist: Double) {
        self.init(pants0: pantsCuff0.pants, index0: pantsCuff0.index, pants1: pantsCuff1.pants, index1: pantsCuff1.index, twist: twist)
    }
    
    init(pants0: Pants, index0: Int, pants1: Pants, index1: Int, twist: Double) {
        _twist = twist
        self._halfLength = pants0.cuffHalfLengths[index0].re
        pantsCuffs[0] = PantsCuff(pants: pants0, index: index0)
        pantsCuffs[1] = PantsCuff(pants: pants1, index: index1)
        //        assert((length - pants1.cuffHalfLengths[index1]).abs < Cuff.matchingTolerance)
        assert(self.halfLength == pants1.cuffHalfLengths[index1])
        setUpTwistsAndGroupoidElementsForThisCuff()
    }
    
    static var matchingTolerance = 0.000001
    
}
