//
//  HDrawable.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 3/31/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

protocol Disked {
    
    var centerPoint: HPoint {get}
    
    var radius: Double {get}
        
}

protocol HDrawable: class, Disked {
    
    func copy() -> HDrawable
    
    // Deprecated
    func transformedBy(_: HyperbolicTransformation) -> HDrawable
    
    func draw()
    
    func drawWithMask(_: HyperbolicTransformation)
    
    func drawWithMaskAndAction(_: Action)
    
    var lineColor: UIColor { get set}
    
    var intrinsicLineWidth: Double {get set}
    
    var fillColorTable: ColorTable {get set}
    
    var fillColor: UIColor {get set}
    
    var mask: HyperbolicTransformation { get set}
    
    var fillColorBaseNumber: ColorNumber {get set}
   
    var useFillColorTable: Bool {get set}
    
    var centerPoint: HPoint {get}
    
    var radius: Double {get}
    
//    var id: Int {get}
    
}

class HDrawableCounter {
    
    private static var _nextId = 0
    
    static var nextId: Int {
        defer { _nextId += 1 }
        return _nextId
    }
    
}

extension HDrawable {
    
    func filteredGroup(group: [Action], cutoffDistance: Double) -> [Action] {
        
        let objectCutoffAbs = distanceToAbs(cutoffDistance + radius)
        
        let objectGroup = group.filter() {$0.motion.appliedTo(centerPoint).abs < objectCutoffAbs}
        
        return objectGroup
    }
    
    func drawWithMask(mask: HyperbolicTransformation) {
        self.mask = mask
        draw()
    }
    
    func drawWithMaskAndAction(A: Action) {
        if useFillColorTable {
            fillColor = fillColorTable[A.action.mapping[fillColorBaseNumber]!]!
        }
        drawWithMask(A.motion)
    }
    
}

