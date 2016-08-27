//: Playground - noun: a place where people can play

import UIKit

@testable import CircleLimitIOS

var pantsArray: [Pants] = []
var cuffArray: [Cuff] = []

enum TestType {
    case t2323, t334
}

func makeInitialGeneralPants() {
    let testType = TestType.t2323
    switch testType {
    case .t2323:
        let cph0 = CuffPlaceholder()
        let pph0 = PantsPlaceholder()
        let pph1 = PantsPlaceholder()
        pph0.numberCuffArray = [NumberCuff.number(2), NumberCuff.number(3), NumberCuff.cuff(cph0, 0)]
        pph1.numberCuffArray = [NumberCuff.number(2), NumberCuff.number(3), NumberCuff.cuff(cph0, 1)]
        (pantsArray, cuffArray) = pantsAndCuffArrayFromPlaceholders([pph0, pph1])
        pantsArray[0].setColor(UIColor.blueColor())
        pantsArray[1].setColor(UIColor.greenColor())
    case .t334:
        let pph = PantsPlaceholder()
        pph.numberCuffArray = [NumberCuff.number(3), NumberCuff.number(3), NumberCuff.number(4)]
        (pantsArray, cuffArray) = pantsAndCuffArrayFromPlaceholders([pph])
        pantsArray[0].setColor(UIColor.greenColor())
    }
}

makeInitialGeneralPants()

let pants = pantsArray[0]
let baseHexagon = pants.hexagons[0]

baseHexagon.rotationArray

//var steppedStates: [[ForwardState]] = [baseHexagon.forwardStates]
let states = baseHexagon.forwardStates

states.count

//for _ in 0...5 {
//    steppedStates.append(steppedStates.last!.map(nextForwardStates).flatten().map({$0}))
//}

let niceStates = states.map({$0.nice})

niceStates[0]
niceStates[1]
niceStates[2]
niceStates[3]


let sl = baseHexagon.sideLengths.map({$0.nice})

sl

let a = baseHexagon.sideLengths[0]

Double.PI.i/a

let pp = baseHexagon.neighbor.map({$0.nice})
pp
pp[1]
pp[3]
pp[4]
pp[5]

baseHexagon.sideLengths





















