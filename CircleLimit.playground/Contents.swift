//: Playground - noun: a place where people can play

import UIKit

@testable import CircleLimitIOS

let s = acosh(2 + 0.i)

let c3 = [1.0, 2.0, 3.0]

let pants0 = Pants(cuffHalfLengths: c3)

let pants1 = Pants(cuffHalfLengths: c3)

var cuffArray: [Cuff] = []

for i in 0...2 {
    cuffArray.append(Cuff(pants0: pants0, index0: i, pants1: pants1, index1: i, twist: 0.5))
}

let pantsArray = [pants0, pants1]

let baseHexagon = pants0.hexagons[0]

let neighbors = baseHexagon.neighbor.map() {$0.nice}

neighbors[0]

neighbors

baseHexagon.id

let q = pantsArray.map({$0.hexagons.map({$0.id})})

q

let f = baseHexagon.forwardStates

let ff = f.map({$0.nice})

ff[0]

ff[1]

ff[2]

ff[3]

ff[4]

ff[5]

(f[0].entry.hexagon!.id, f[0].newMotion.u.nice, f[0].newMotion.v.nice, f[0].state)




