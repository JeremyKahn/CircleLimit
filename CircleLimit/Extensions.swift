//
//  Extensions.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 11/25/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

// MARK: Arithmetic and mathematical functions
infix operator %%: MultiplicationPrecedence

/**
 - returns: lhs reduced modulo the absolute value of rhs
 - remark: Always returns a number between 0 (inclusive) and |rhs| (exclusive)
 */
func %%(left: Int, right: Int) -> Int {
    if (right == 0) {return 0}
    if (right < 0) {return left %% (-right) }
    if (left >= 0) {return left % right}
    return left % right + right
}

func %%(left: Double, right: Double) -> Double {
    if (right == 0) {return 0}
    if (right < 0) {return left %% (-right) }
    if (left >= 0) {return left.truncatingRemainder(dividingBy: right)}
    return left.truncatingRemainder(dividingBy: right) + right
}

func coth(_ x: Double) -> Double {
    return 1/tanh(x)
}

func acoth(_ y: Double) -> Double {
    return atanh(1/y)
}

func coth<T>(_ z: Complex<T>) -> Complex<T> {
    return tanh(z).inverse
}

func acoth<T>(_ z: Complex<T>) -> Complex<T> {
    return atanh(z.inverse)
}

extension Complex {
    var inverse: Complex<T> {
        let aa = abs2
        return Complex<T>(re/aa, -im/aa)
    }
}

// MARK: Timing
extension Timer {
    

    
}

extension Character {
    var int: Int? {
        return Int(String(self))
    }
}

extension Date {
    
    var millisecondsToPresent: Int {
        return timeInMillisecondsSince(self)
    }
    
}

func timeInMillisecondsSince(_ date: Date) -> Int {
    return (1000 * Date().timeIntervalSince(date)).int
}

func secondsSince(_ date: Date) -> Double {
    return Date().timeIntervalSince(date)
}

// MARK: Printing
func print(_ s: String, when condition: Bool) {
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

func randomDouble() -> Double {
    let n = 1000000
    return Double(Int(arc4random()) % n) / Double(n)
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

extension String {
    func atNumericalIndex(n: Int) -> Character {
        let nn = index(startIndex, offsetBy: n)
        return self[nn]
    }
}

extension Dictionary {
    
    func valuesForKeys(_ keys: [Key]) -> [Value] {
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
    
    mutating func insertAtIndices(_ instructions: [(Int, Element)]) {
        let sorted = instructions.sorted() { $0.0 < $1.0  }
        for i in 0..<sorted.count {
            let (j, a) = sorted[i]
            insert(a, at: j + i)
        }
    }
    
    mutating func insertAfterIndices(_ instructions: [(Int, Element)]) {
        let incremented = instructions.map { ($0.0 + 1, $0.1) }
        insertAtIndices(incremented)
    }

    func at(_ indices: [Int]) -> [Element] {
        return indices.map({self[$0]})
    }
    
    func leastElementFor<U: Comparable>(_ f: @escaping (Element) -> U) -> Element? {
        return self.min(by: {f($0) < f($1)})
    }
        
    func sortByFunction<U: Comparable>(_ f: (Element) -> U) -> [Element] {
        return sorted(by: {f($0) < f($1)})
    }
    
    func sum<T: Summable>(_ f: @escaping (Element) -> T) -> T {
        return reduce(T.zero, {$0 + f($1)})
    }

}

extension Double: Summable {
    
    static var zero = 0.0
    
}

protocol Summable {
    static func+(lhs: Self, rhs: Self) -> Self
    
    static var zero: Self {get}
}

// MARK: Geometry

extension Complex {
    var abs2: T {
        return re * re + im * im
    }
}

class ComplexConstant {
    
    public static let zero = Complex64(0.0, 0.0)
    public static let one = Complex64(1.0, 0.0)
    public static let minusOne = Complex64(-1.0, 0.0)
    
}

