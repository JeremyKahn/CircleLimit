//
//  HyperbolicTransformation.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 1/6/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

typealias HTrans = HyperbolicTransformation

typealias HUVect = HTrans

// representation is z -> lambda * (z - a)/(1 - a.bar * z)
struct HyperbolicTransformation : CustomStringConvertible, Locatable {
    
    var a: Complex64 {
        return -v/u
    }
    
    var lambda: Complex64 {
        return u/u.conj
    }
    
    var u: Complex64 = Complex64(1.0, 0.0)
    
    var v: Complex64 = Complex64()
    
    // MARK: Initializers
    
    // Does not check that the input is valid
    init(u: Complex64, v: Complex64) {
        self.u = u
        self.v = v
    }
    
    init(lambda: Complex64) {
        var l = lambda
        l.abs = 1.0
        u = sqrt(l)
    }
    
    init(a: Complex64, lambda: Complex64) {
        var l = lambda
        l.abs = 1.0
        u = sqrt(l/(1 - a.abs2))
        v = -u * a
    }
    
    init(a: Complex64) {
        u = sqrt(1 + 0.i/(1 - a.abs2))
        v = -u * a
    }
    
    init(a: HPoint) {
        self.init(a: a.z)
    }
    
    init() {
    }
    
    init(rotationInTurns: Double) {
        let x = rotationInTurns * Double.PI * 2
        self.init(rotationInRadians: x)
    }
    
    init(rotationInRadians: Double) {
        u = exp(rotationInRadians.i/2)
    }
    
    init(hyperbolicTranslation: Double) {
        let t = hyperbolicTranslation/2
        u = cosh(t) + 0.i
        v = sinh(t) + 0.i
    }
    
    // MARK: Computed Properties
    var abs: Double {
        return v.abs/u.abs
    }
    
    var distance: Double {
        return absToDistance(abs)
    }
    
    // MARK: Instructions
    static func goForward(distance: Double) -> HyperbolicTransformation {
        return HyperbolicTransformation(hyperbolicTranslation: distance)
    }
    
    static func rotate(angle: Double) -> HTrans {
        return HTrans(rotationInRadians: angle)
    }
    
    static let turnLeft = HyperbolicTransformation(lambda: 1.i)
    
    static let turnRight = HyperbolicTransformation(lambda: -1.i)
    
    static let turnAround = HyperbolicTransformation(lambda: -1 + 0.i)
    
    var appliedToOrigin: HPoint {
        return appliedTo(HPoint())
    }
    
    var turnLeft: HTrans {
        return following(HTrans.turnLeft)
    }
    
    var turnRight: HTrans {
        return following(HTrans.turnRight)
    }
    
    var turnAround: HTrans {
        return following(HTrans.turnAround)
    }
    
    func rotate(angle: Double) -> HTrans {
        return following(HTrans.rotate(angle))
    }
    
    func goForward(distance: Double) -> HTrans {
        return following(HTrans.goForward(distance))
    }
    
    // MARK: Group operations
    static let identity = HyperbolicTransformation()
    
    func appliedTo(z: Complex64) -> Complex64 {
        let w = (u * z + v) / (v.conj * z + u.conj)
        return w
    }
    
    func appliedTo(z: HPoint) -> HPoint {
        return HPoint(appliedTo(z.z))
    }
    
    func appliedTo(g: HeuristicGeodesic) -> HeuristicGeodesic {
        return g.transformedBy(self)
    }
    
    func appliedTo(M: HUVect) -> HUVect {
        return following(M)
    }
    
    var inverse: HyperbolicTransformation
    { return HyperbolicTransformation(u: u.conj, v: -v) }
    
    // So far this finds the fixed point for an elliptic element
    var fixedPoint: HPoint? {
        if v == 0 {
            if u * u == 1 { return nil }
            else { return HPoint() }
        }
        let thingInside = 1 - u.re * u.re
        guard thingInside > 0 else {return nil}
        var im = (u.im.abs - sqrt(thingInside))
        im = u.im > 0 ? im : -im
        let z = im.i/v.conj
        return HPoint(z)
    }
    
    // This is very close to correct when the axis is far from the origin
    // We return nil if the transformation is not hyperbolic
    var approximateDistanceOfTranslationAxisToOrigin: Double? {
        if v == 0 { return nil }
        let thingInside = u.re * u.re - 1
        guard thingInside > 0 else {return nil}
        let y = sqrt(thingInside)/v.abs
        return log(2.0) - log(y)
    }
    
    func approximateDistanceOfTranslationAxisTo(p: HPoint) -> Double? {
        let tP = HTrans(a: p)
        let mP = tP.following(self).following(tP.inverse)
        return mP.approximateDistanceOfTranslationAxisToOrigin
    }
    
    var trace: Double {
        return 2 * u.re
    }
    
    /// ETL is e to the translation length
    var translationLength: Double? {
        guard u.re >= 1 else {return nil}
        return 2 * acosh(u.re)
    }
    
    //    func inverse() -> HyperbolicTransformation {
    //        return HyperbolicTransformation(a: -a * lambda, lambda: lambda.conj)
    //    }
    
    func following(B: HyperbolicTransformation) -> HyperbolicTransformation {
        let r = u * B.u + v * B.v.conj
        let s = u * B.v + v * B.u.conj
        return HyperbolicTransformation(u: r, v: s)
    }
    
    func toThe(n: Int) -> HyperbolicTransformation {
        assert(n >= 0)
        var M = HyperbolicTransformation()
        for _ in 0..<n {
            M = M.following(self)
        }
        return M
    }
    
    
    // MARK: Location, comparison, and description
    typealias Location = Int
    
    // right now location just based on absolute value
    var location: Location {
        return Int(10 * u.abs2)
    }
    
    static func neighbors(l: Location) -> [Location] {
        return [l-1, l, l+1]
    }
    
    static var tolerance = 0.001
    
    func closeToIdentity() -> Bool {
        return closeToIdentity(HyperbolicTransformation.tolerance)
    }
    
    // This guarantees that v is about 0 and u is about plus or minus 1
    func closeToIdentity(tolerance: Double) -> Bool {
        return v.abs < tolerance && u.im.abs < tolerance
    }
    
    func nearTo(B:HyperbolicTransformation) -> Bool {
        return nearTo(B, tolerance: HyperbolicTransformation.tolerance)
    }
    
    func nearTo(B:HyperbolicTransformation, tolerance: Double) -> Bool {
        let E = self.following(B.inverse)
        return E.closeToIdentity(tolerance)
    }
    
    var description : String {
        return "a: " + a.nice + " lambda: " + lambda.nice
    }
    
    // MARK: Random generation
    static func randomInstance() -> HyperbolicTransformation {
        let a = (randomDouble() + randomDouble().i)/sqrt(2)
        let lambda = exp((randomDouble() * Double.PI * 2).i)
        return HyperbolicTransformation(a: a, lambda: lambda)
    }
    
}


func == (left: HyperbolicTransformation, right: HyperbolicTransformation) -> Bool {
    return left.nearTo(right)
}

func != (left: HyperbolicTransformation, right: HyperbolicTransformation) -> Bool {
    return !(left == right)
}

