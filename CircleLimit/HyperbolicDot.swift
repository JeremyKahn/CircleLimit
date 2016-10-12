//
//  HyperbolicDot.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 3/31/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

class HyperbolicDot : HDrawable {
    
    func copy() -> HDrawable {
        return HyperbolicDot(dot: self)
    }
    
    var centerPoint: HPoint {
        return center
    }
    
    var center: HPoint = HPoint()
    
    var mask: HyperbolicTransformation = HyperbolicTransformation()
    
    var radius : Double {
        return size
    }
    
    var size = 0.03
    
    var intrinsicLineWidth: Double = 0
    
    var lineColor: UIColor = UIColor.black
    
    var fillColorTable: ColorTable = [1: UIColor.blue, 2: UIColor.green, 3: UIColor.red, 4: UIColor.yellow]
    
    var fillColor: UIColor = UIColor.purple
    
    var fillColorBaseNumber = ColorNumber.baseNumber
    
    var useFillColorTable = true
    
    init(dot: HyperbolicDot) {
        self.center = dot.center
        self.size  = dot.size
        self.lineColor = dot.lineColor
    }
    
    init(center: HPoint, radius: Double) {
        self.center = center
        self.size = radius
    }
    
    init(center: HPoint, radius: Double, lineColor: UIColor) {
        self.center = center
        self.size = radius
        self.lineColor = lineColor
    }
    
    init(center: HPoint) {
        self.center = center
    }
    
    func drawWithMask(_ mask: HyperbolicTransformation) {
        let dot = self.transformedBy(mask)
        dot.draw()
    }
    
    func draw() {
        let (x, y, r) = poincareDiskCenterRadius()
        let euclDotCenter = CGPoint(x: x, y: y)
        let c = circlePath(euclDotCenter, radius: CGFloat(r))
        fillColor.set()
        c.fill()
//        lineColor.set()
//        c.stroke()
    }
    
    func poincareDiskCenterRadius() -> (centerX: Double, centerY: Double, radius: Double) {
        let dotR = center.abs
        let E = (1 + dotR)/(1 - dotR)
        let M = exp(radius)
        let Q0 = M * E
        let tPlus = (Q0 - 1)/(Q0 + 1)
        let Q1 = E / M
        let tMinus = (Q1 - 1)/(Q1 + 1)
        let euclCenterAbs = (tPlus + tMinus)/2
        let euclR = (tPlus - tMinus)/2
        //        println("dotR: \(dotR) E: \(E) M: \(M) Q0: \(Q0) Q1: \(Q1) tPlus: \(tPlus) tMinus: \(tMinus)")
        let complexEuclCenter = Complex(abs: euclCenterAbs, arg: center.arg)
        return(complexEuclCenter.re, complexEuclCenter.im, euclR)
    }
    
    func transformBy(_ M: HyperbolicTransformation) {
        center = M.appliedTo(center)
    }
    
    func transformedBy(_ M: HyperbolicTransformation) -> HDrawable {
        let dot = HyperbolicDot(dot: self)
        dot.transformBy(M)
        return dot
    }
}

