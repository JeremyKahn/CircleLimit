//
//  Cuff.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/25/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

struct PantsCuff {
    
    var pants: Pants
    var index: Int
    
    func setLength(newLength: Double) {
        pants.cuffHalfLengths[index] = newLength
    }
    
}

class Cuff {
    
    // This gives up the point at the middle of the selected cuff segment
    var baseMask: HTrans {
        return pantsCuffs[0].pants.baseMask
    }
    
    var guidelineCenterpoint: HTrans {
        let pants = pantsCuffs[0].pants
        let sideIndex = pants.sideIndexForCuffIndex(pantsCuffs[0].index, AndHexagonIndex: 0)
        return pants.baseMask.appliedTo(pants.hexagons[0].end[sideIndex])
    }
    
    var twist: Double  {
        didSet {
            setUpTwistsAndGroupoidElementsForThisCuff()
        }
    }
    
    // Tells the two pants to set up the groupoid elements between the two pants
    func setUpTwistsAndGroupoidElementsForThisCuff() {
        for i in 0...1 {
            let pantsCuff = pantsCuffs[i]
            let otherPantsCuff = pantsCuffs[1-i]
            pantsCuff.pants.adjacenciesAndTwists[pantsCuff.index] = (otherPantsCuff.pants, otherPantsCuff.index, twist)
        }
        for pantsCuff in pantsCuffs {
            pantsCuff.pants.setUpGroupoidElementToAdjacentPantsForIndex(pantsCuff.index, updateNeighbor: false)
        }
    }
    
    var length: Double {
        didSet {
            for pantsCuff in pantsCuffs {
                pantsCuff.setLength(length)
            }
        }
    }
    var pantsCuffs: [PantsCuff!] = [nil, nil]
    
    var guideline: HDrawable {
        return pantsCuffs[0].pants.cuffGuidelines[pantsCuffs[0].index]
    }
    
    var transformedGuideline: HDrawable {
        return guideline.transformedBy(baseMask)
    }
    
    
    init(pants0: Pants, index0: Int, pants1: Pants, index1: Int, twist: Double) {
        self.twist = twist
        self.length = pants0.cuffHalfLengths[index0]
        pantsCuffs[0] = PantsCuff(pants: pants0, index: index0)
        pantsCuffs[1] = PantsCuff(pants: pants1, index: index1)
        //        assert((length - pants1.cuffHalfLengths[index1]).abs < Cuff.matchingTolerance)
        assert(self.length == pants1.cuffHalfLengths[index1])
        setUpTwistsAndGroupoidElementsForThisCuff()
    }
    
    static var matchingTolerance = 0.000001
    
}
