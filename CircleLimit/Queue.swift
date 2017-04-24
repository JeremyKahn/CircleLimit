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
    
    func add(_: Element)
    
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
    
    var asArray: [Element] {
        return [Element](elements[head..<elements.count])
    }
    
}

class QueueTable<Element> {
    
    init(maxPriority: Int) {
        self.maxPriority = maxPriority
        queues = Array(repeating: FastQueue<Element>(), count: maxPriority + 1)
        currentPriority = maxPriority + 1
    }
    
    let maxPriority: Int
    
    var currentPriority: Int
    
    let queues: [FastQueue<Element>]
    
    // the second condition should be redundant
    var hasNext: Bool {
        return currentPriority <= maxPriority && queues[currentPriority].hasNext
    }
    
    // We set currentPriority to be the index for the next nonempty queue
    var getNext: Element? {
        guard hasNext else {
            return nil
        }
        let nextObject = queues[currentPriority].getNext
        while currentPriority <= maxPriority && !queues[currentPriority].hasNext {
            currentPriority += 1
        }
        return nextObject
    }
    
    func add(_ e: Element, priority: Int) {
        guard priority <= maxPriority else { return }
        queues[priority].add(e)
        if priority < currentPriority {
            currentPriority = priority
        }
    }
    
    var asArray: [Element] {
        var result: [Element] = []
        for i in currentPriority...maxPriority {
            result += queues[i].asArray
        }
        return result
    }
}
