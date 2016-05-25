//
//  Extensions.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 11/25/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

// MARK: Arithmetic and mathematical functions
infix operator %% {associativity left precedence 150}

func %%(left: Int, right: Int) -> Int {
    if (right == 0) {return 0}
    if (right < 0) {return left %% (-right) }
    if (left >= 0) {return left % right}
    return left % right + right
}

func %%(left: Double, right: Double) -> Double {
    if (right == 0) {return 0}
    if (right < 0) {return left %% (-right) }
    if (left >= 0) {return left % right}
    return left % right + right
}

func coth(x: Double) -> Double {
    return 1/tanh(x)
}

func acoth(y: Double) -> Double {
    return atanh(1/y)
}


// MARK: Timing
extension NSTimer {
    

    
}

func timeInMillisecondsSince(date: NSDate) -> Int {
    return (1000 * NSDate().timeIntervalSinceDate(date)).int
}

func secondsSince(date: NSDate) -> Double {
    return NSDate().timeIntervalSinceDate(date)
}

// MARK: Printing
func print(s: String, when condition: Bool) {
    if condition {
        print(s)
    }
}

protocol NicelyPrinting {
    
    var nice: String {get}
    
}

extension CGFloat: NicelyPrinting {

    var nice: String {
        return String(format: "%.3f", self)
    }
    
}

extension Double: NicelyPrinting {
    
    var nice: String {
        return String(format: "%.3f", self)
    }
    
    var int: Int {
        return Int(self)
    }
    
}

extension Complex where T : NicelyPrinting {
    var nice: String {
        let plus = im.isSignMinus ? "" : "+"
        return "(\(re.nice)\(plus)\(im.nice).i)"
    }
}

// MARK: Collection Extensions

extension Dictionary {
    
    func valuesForKeys(keys: [Key]) -> [Value] {
        var result: [Value] = []
        for key in keys {
            if let value = self[key] {
                result.append(value)
            }
        }
        return result
    }
    
}

extension Array {
    
    mutating func insertAtIndices(instructions: [(Int, Element)]) {
        let sorted = instructions.sort() { $0.0 < $1.0  }
        for i in 0..<sorted.count {
            let (j, a) = sorted[i]
            insert(a, atIndex: j + i)
        }
    }
    
    mutating func insertAfterIndices(instructions: [(Int, Element)]) {
        let incremented = instructions.map { ($0.0 + 1, $0.1) }
        insertAtIndices(incremented)
    }

}

// MARK: Geometry

extension Complex {
    var abs2: T {
        return re * re + im * im
    }
}

