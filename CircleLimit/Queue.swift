//
//  Queue.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/23/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

// In principle we should be able to make this conform to SequenceType
protocol Queue: Sequence, IteratorProtocol {
    associatedtype Element
    
    func add(_: Element)
    
    var hasNext: Bool {get}
    
    func next() -> Element?
    
    var peekNext: Element? {get}
    
    var numberOfElements: Int {get}
    
    var asArray: [Element] {get}
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
    
    func next() ->  Element? {
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
    
    var numberOfElements: Int {
        return elements.count - head
    }
    
    var asArray: [Element] {
        return [Element](elements[head..<elements.count])
    }
    
}

// Right now there's no check to see if the priority is negative, or too large.
class QueueTable<Element>: Sequence, IteratorProtocol {
    
    // The least index for a nonempty queue, or the number of queues.
    var currentPriority = 0
    
    var queues: [FastQueue<Element>] = []
    
    // the second condition should be redundant
    var hasNext: Bool {
        return currentPriority < queues.count && queues[currentPriority].hasNext
    }
    
    // We set currentPriority to be the index for the next nonempty queue
    func next() ->  Element? {
        guard hasNext else {
            return nil
        }
        let nextObject = queues[currentPriority].next()
        while currentPriority < queues.count && !queues[currentPriority].hasNext {
            currentPriority += 1
        }
        return nextObject
    }
    
    func add(_ e: Element, priority: Int) {
        if !hasNext {
            currentPriority = priority
        }
        if priority >= queues.count {
            for _ in queues.count...priority {
                queues.append(FastQueue<Element>())
            }
        }
        queues[priority].add(e)
        if priority < currentPriority {
            currentPriority = priority
        }
    }
    
    func asArrayWithPriorityLessThan(_ n: Int) -> [Element] {
        let maxIndex = Swift.min(n, queues.count)
        var result: [Element] = []
        for queue in queues[0..<maxIndex] {
            result += queue.asArray
        }
        return result
    }
    
    var asArray: [Element] {
        var result: [Element] = []
        for queue in queues {
            result += queue.asArray
        }
        return result
    }
    
    var asArrayOfArrays: [[Element]] {
        return queues.map() {$0.asArray}
    }
}
