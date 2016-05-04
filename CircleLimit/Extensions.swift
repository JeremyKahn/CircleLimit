//
//  Extensions.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 11/25/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

extension NSTimer {
    

    
}

func timeInMillisecondsSince(date: NSDate) -> Int {
    return (1000 * NSDate().timeIntervalSinceDate(date)).int
}


func print(s: String, when condition: Bool) {
    if condition {
        print(s)
    }
}

protocol NicelyPrinting {
    
    var nice: String {get}
    
}

extension Double: NicelyPrinting {
    
    var nice: String {
        return String(format: "%.3f", self)
    }
    
    var int: Int {
        return Int(self)
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

extension Complex {
    var abs2: T {
        return re * re + im * im
    }
}

extension Complex where T : NicelyPrinting {
    var nice: String {
        let plus = im.isSignMinus ? "" : "+"
        return "(\(re.nice)\(plus)\(im.nice).i)"
    }
}