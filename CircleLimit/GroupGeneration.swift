//
//  GroupGeneration.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 1/6/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import UIKit

// TODO: Replace Action with a lookup table with HyperbolicTransformation's as keys

struct Action: Locatable {
    
    var motion: HyperbolicTransformation
    
    var action: ColorNumberPermutation
    
    typealias Location = Int
    
    var location: Location {
        return motion.location
    }
    
    static func neighbors(location: Location)->  [Location] {
        return HyperbolicTransformation.neighbors(location)
    }
    
    init() {
        motion = HyperbolicTransformation()
        action = ColorNumberPermutation()
    }
    
    init (motion: HyperbolicTransformation, action: ColorNumberPermutation) {
        self.motion = motion
        self.action = action
    }
    
    init(M: HyperbolicTransformation, P: ColorNumberPermutation) {
        motion = M
        action = P
    }
    
    init(M: HyperbolicTransformation) {
        motion = M
        action = ColorNumberPermutation()
    }
    
}



// right now we're using _semigroup_ generators
// this generates all elements of the semigroup which can be realized as a path of words in the generators, each meeting the cutoff
func generatedGroup(generators: [Action], bigCutoff: Double) -> [Action] {
    let startTime = NSDate()
    let bigGroup = LocationTable<Action>()
    bigGroup.add(Action())
    bigGroup.add(generators)
    var frontier = generators
    while(frontier.count > 0) {
        var newFrontier: [Action] = []
        for M in frontier {
            search: for T in generators {
                let X = M.motion.following(T.motion)
                let P = M.action.following(T.action)
                if X.a.abs > bigCutoff  {
                    continue
                }
                //              Check to see if X is already listed in bigGroup
                for U in bigGroup.arrayForNearLocation(X.location) {
                    if U.motion.nearTo(X) {
                        continue search
                    }
                }
                let A = Action(M: X, P: P)
                newFrontier.append(A)
                bigGroup.add(A)
                //                println("Found group element number \(++n): \(X.a, X.lambda)")
            }
        }
        frontier = newFrontier
    }
    print("Found \(bigGroup.count) elements in the big group")
    let timeTaken = 1000 * NSDate().timeIntervalSinceDate(startTime)
    print("Time taken: \(timeTaken) ms")
    return bigGroup.arrayForm
}

// the hyperbolic length of c in triangle ABC
func lengthFromAngles(A: Double, B: Double, C:Double) -> Double {
    return acosh((cos(A) * cos(B) + cos(C)) / (sin(A) * sin(B)))
}


// produces the standard three (redundant) generators for an orientable pqr triangle group
func pqrGeneratorsAndGuidelines(p: Int, q: Int, r: Int) -> ([HyperbolicTransformation], [HDrawable]) {
    let pi = Double.PI
    let (pp, qq, rr) = (pi / Double(p), pi / Double(q), pi / Double(r))
    assert(pp + qq + rr < pi)
    let b = lengthFromAngles(pp, B: rr, C: qq)
    let c = lengthFromAngles(pp, B: qq, C: rr)
    let A2 = HyperbolicTransformation(rotationInRadians: pp)
    let A = A2.following(A2)
    let TB = HyperbolicTransformation(hyperbolicTranslation: b)
    let TC = HyperbolicTransformation(hyperbolicTranslation: c)
    let RTB = A2.following(TB)
    let RQ = HyperbolicTransformation(rotationInRadians: 2 * qq)
    let RR = HyperbolicTransformation(rotationInRadians: 2 * rr)
    let B = TC.following(RQ).following(TC.inverse)
    let C = RTB.following(RR).following(RTB.inverse)
    let identity = HyperbolicTransformation.identity
    assert(A.toThe(p) == identity)
    assert(B.toThe(q) == identity)
    assert(C.toThe(r) == identity)
    assert(A.following(B).following(C) == identity)
    
    let P = HPoint()
    let Q = TC.appliedTo(P)
    let R = RTB.appliedTo(P)
    
    let guidelines = [HyperbolicPolyline([P, Q]), HyperbolicPolyline([Q, R]), HyperbolicPolyline([R, P])]
    guidelines.forEach({$0.touchable = false})
    let g2 = guidelines.map {$0 as HDrawable}
    return ([A, B, C], g2)
}

func sideInRightAngledHexagonWithOpposite(a: Double, andAdj b: Double, andAdj c: Double) -> Double {
    let numerator = cosh(a) * cosh(b) + cosh(c)
    let denominator = sinh(a) * sinh(b)
    return acosh(numerator/denominator)
}


// The a, b, and c are the _half_ lengths of the cuffs
func pantsGroupGeneratorsAndGuidelines(a a: Double, b: Double, c: Double) -> ([HyperbolicTransformation], [HDrawable]) {
    let C = sideInRightAngledHexagonWithOpposite(c, andAdj: a, andAdj: b)
    let A = sideInRightAngledHexagonWithOpposite(a, andAdj: b, andAdj: c)
    let B = sideInRightAngledHexagonWithOpposite(b, andAdj: a, andAdj: b)
    let aTrans = HyperbolicTransformation.goForward(2 * a)
    let left = HyperbolicTransformation.turnLeft
    let right = HyperbolicTransformation.turnRight
    let CForward = HyperbolicTransformation.goForward(C)
    let bTrans = left.following(CForward).following(left).following(HyperbolicTransformation.goForward(2 * b)).following(left).following(CForward).following(left)
    let cTrans = (bTrans.following(aTrans)).inverse
    let generators = [aTrans, bTrans, cTrans]
     let aC = HyperbolicTransformation()
    let bC = aC.following(left).following(CForward).following(left)
    let bA = bC.following(HyperbolicTransformation.goForward(b))
    let cA = bA.following(left).following(HyperbolicTransformation.goForward(A)).following(left)
    let cB = cA.following(HyperbolicTransformation.goForward(c))
    let aB = aC.following(HyperbolicTransformation.goForward(-a))
    let guidelines = [HyperbolicPolyline([aC.appliedToOrigin, bC.appliedToOrigin]),
                      HyperbolicPolyline([bA.appliedToOrigin, cA.appliedToOrigin]),
                      HyperbolicPolyline([cB.appliedToOrigin, aB.appliedToOrigin]),
                      HyperbolicPolyline([bC.appliedToOrigin, bTrans.following(bC).appliedToOrigin]),
                      HyperbolicPolyline([aC.appliedToOrigin, aTrans.following(aC).appliedToOrigin]),
                      HyperbolicPolyline([cA.appliedToOrigin, cTrans.following(cA).appliedToOrigin])
        
    ] as [HDrawable]
    return (generators, guidelines)
}

typealias ColorTable = Dictionary<ColorNumber, UIColor>

protocol HasUniverse: Hashable {
    
    static var universe: Set<Self> { get }
    
}

typealias ColorNumber = Int

extension ColorNumber: HasUniverse {
    
    static var universe = Set<ColorNumber>([1, 2, 3, 4])
    
    static var baseNumber = 1
    
}

//class ColorNumber : Hashable {
//    
//    var number: Int
//    
//    init(_ n: Int) {
//        number = n
//    }
//    
//    var hashValue: Int {
//        return number.hashValue
//    }
//    
//    static var universe: Set<ColorNumber> = [ColorNumber(1), ColorNumber(2), ColorNumber(3), ColorNumber(4)]
//    
//    
//}
//
//func== (lhs: ColorNumber, rhs: ColorNumber) -> Bool {
//    return lhs.number == rhs.number
//}


class Permutation<Element: HasUniverse>: Equatable {
    
    var mapping = [Element: Element]()
    
    init() {
        for i in Element.universe
        {
            mapping[i] = i
        }
    }
    
    init(mapping: [Element: Element]) {
        self.mapping = mapping
    }
    
    func following(y: Permutation<Element>) -> Permutation<Element> {
        var newMapping = [Element: Element]()
        for i in Element.universe {
            newMapping[i] = mapping[y.mapping[i]!]!
        }
        return Permutation<Element>(mapping: newMapping)
    }
    
}

func ==<Element>(lhs: Permutation<Element>, rhs: Permutation<Element>) -> Bool{
    return lhs.mapping == rhs.mapping
}

typealias ColorNumberPermutation = Permutation<ColorNumber>
