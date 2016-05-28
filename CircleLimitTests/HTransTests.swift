//
//  HTransTests.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/28/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit
import XCTest
import CircleLimit


class HTransTests: XCTestCase {
    
    func testAbsToDistanceAndBack() {
        for _ in 1...1000 {
            let a = randomDouble()
            XCTAssert((a-absToDistance(distanceToAbs(a))) < 0.0001)
        }
    }
    
    // This of course has a small chance of failing
    func testNontrivial() {
        for _ in 1...10 {
            let a = HTrans.randomInstance()
            let b = HTrans.randomInstance()
            XCTAssertFalse(a.closeToIdentity())
            XCTAssertFalse(a.nearTo(b))
        }
    }
    
    func testSpecialUnitary() {
         for _ in 1...1000 {
            let M = HTrans.randomInstance()
            let d = M.u.abs2 - M.v.abs2 - 1.0
            XCTAssert(d.abs < 0.000001)
        }
    }
    
    // This might fail because of round-off error
    func testOldToNewToOld() {
        for _ in 1...1000 {
            let p = HPoint.randomInstance()
            let lambda = exp(2 * Double.PI * randomDouble().i)
            let M = HTrans(a: p.z, lambda: lambda)
            XCTAssert(M.a =~ p.z && M.lambda =~ lambda)
        }
    }
    
    func testInverse() {
        for _ in 1...1000 {
            let a = HTrans.randomInstance()
            XCTAssert(a.following(a.inverse).closeToIdentity())
            XCTAssert(a.inverse.following(a).closeToIdentity())
        }
    }
    
    func testApplicationValidity() {
        for _ in 1...1000 {
            let p = HPoint.randomInstance()
            let a = HTrans.randomInstance()
            let _ = a.appliedTo(p)
        }
        XCTAssert(true)
    }
    
    func testGroupAction() {
        for _ in 1...1000 {
            let p = HPoint.randomInstance()
            let a = HTrans.randomInstance()
            let b = HTrans.randomInstance()
            let q0 = a.following(b).appliedTo(p)
            let q1 = a.appliedTo(b.appliedTo(p))
            XCTAssert(q0.distanceTo(q1) < 0.0001)
        }
    }
    
    func testAssociate() {
        for _ in 1...1000 {
            let a = HTrans.randomInstance()
            let b = HTrans.randomInstance()
            let c = HTrans.randomInstance()
            XCTAssert(a.following(b.following(c)).nearTo(a.following(b).following(c)))
        }
    }
}
