//
//  Queue.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/23/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

// In principle we should be able to make this conform to SequenceType
protocol Queue {
    associatedtype Element
    
    var getNext: Element? {get}
    
    func add(_ e: Element)
    
    var hasNext: Bool {get}
    
    var peekNext: Element? {get}
    
    
}

// This is a fast, somewhat silly implementation of a queue
class FastQueue<Element> : Queue {
    
    fileprivate var resetPoint: Int {
        return elements.count / 2
    }
    
    fileprivate var elements: [Element] = []
    
    fileprivate var head: Int = 0
    
    var hasNext: Bool {
        return head < elements.count
    }
    
    var getNext: Element? {
        guard hasNext else {return nil}
        let result = elements[head]
        head += 1
        if head > resetPoint {
            let newElements = elements[head..<elements.count]
            head = 0
            elements = [Element](newElements)
        }
        return result
    }
    
    func add(_ e: Element) {
        elements.append(e)
    }
    
    var peekNext: Element? {
        guard hasNext else {return nil}
        return elements[head]
    }
    
}
