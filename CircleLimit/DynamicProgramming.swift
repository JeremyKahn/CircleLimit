//
//  DynamicProgramming.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 8/4/15.
//  Copyright (c) 2015 Jeremy Kahn. All rights reserved.
//

import Foundation

// We require that we have i in 1...n, and then j in 0..<i
func bestSequenceTo(n: Int, toMinimizeSumOf f: (Int, Int) -> Int, withConstraint allowed: (Int, Int) -> Bool) -> [Int] {
    
    var bestSequenceTo : [[Int]] = [[Int]](count: n+1, repeatedValue: [])
    bestSequenceTo[0] = [0]
    var minimalSumTo : [Int] = [Int](count: n+1, repeatedValue: 0)
    
    // This uses storage that is quadratic in n, which is lazy
    for i in 1...n {
        var bestSumToI = Int.max
        var bestJ = -1
        for j in 0..<i {
            if allowed(j, i) {
                let bestSumWithJ = minimalSumTo[j] + f(j, i)
                if bestSumWithJ <= bestSumToI {
                    bestSumToI = bestSumWithJ
                    bestJ = j
                }
            }
        }
        assert(bestJ >= 0, "For index \(i) we failed to get an allowable j")
        minimalSumTo[i] = bestSumToI
        bestSequenceTo[i] = bestSequenceTo[bestJ] + [i]
    }
//    print(bestSequenceTo[n])
    return bestSequenceTo[n]
}

func subsequenceOf<T>(a: [T], withIndices indices: [Int]) -> [T] {
    var b: [T] = []
    for i in indices {
        b.append(a[i])
    }
    return b
}