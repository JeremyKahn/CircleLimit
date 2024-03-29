//
//  Groupoid.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 5/24/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation


struct GroupoidElement : Locatable {
    
    var M: HTrans
    unowned var start: AnyObject
    unowned var end: AnyObject
    
    func sameAs(_ t: GroupoidElement) -> Bool {
        return start === t.start && end === t.end && M.nearTo(t.M)
    }
    
    func canFollow(_ t: GroupoidElement) -> Bool {
        return end === t.start
    }
    
    func following(_ t: GroupoidElement) -> GroupoidElement {
        assert(canFollow(t))
        return GroupoidElement(M: M.following(t.M), start: start, end: t.end)
    }
    
    var location: Int {
        return M.location
    }
    
    static func neighbors(_ t: Int) -> [Int] {
        return [t-1, t, t+1]
    }
    
    static func identity(_ home: AnyObject) -> GroupoidElement {
        return GroupoidElement(M: HTrans.identity, start: home, end: home)
    }
    
}

func generatedGroupoid(_ base: [GroupoidElement], generators: [GroupoidElement], withinBounds: @escaping (GroupoidElement) -> Bool, maxTime: Double) -> [GroupoidElement] {
    let rightMultiplyByGenerators = {
        [withinBounds]
        (t: GroupoidElement) -> [GroupoidElement] in
        let allowed = generators.filter({t.canFollow($0)})
        let list = allowed.map() {t.following($0)}
        return list.filter(withinBounds)
    }
    let nearEnoughAndMatching = { (t0: GroupoidElement, t1: GroupoidElement) -> Bool in t0.sameAs(t1)}
    let result = leastFixedPoint(base, map: rightMultiplyByGenerators, match: nearEnoughAndMatching, maxTime: maxTime)
    return result
}

func groupFromGroupoid(_ groupoid: [GroupoidElement], startingAndEndingAt home: AnyObject) -> [HTrans] {
    let result = groupoid.filter({$0.start === home && $0.end === home}).map({$0.M})
    return result
}

func leastElementOfGroupoid(_ groupoid: [GroupoidElement], toGoFrom start: AnyObject, to end: AnyObject) -> GroupoidElement? {
    let candidates = groupoid.filter({$0.start === start && $0.end === end})
    guard candidates.count > 0 else {return nil}
    var bestCandidate = candidates.first!
    for candidate in candidates {
        if candidate.M.distance < bestCandidate.M.distance {
            bestCandidate = candidate
        }
    }
    return bestCandidate
}

// Grows the list without checking for repetition
func fastLeastFixedPoint<T, U>(_ base: [T], expand: (T) -> [T], good: (T) -> Bool, project: (T) -> U) -> [U] {
    let startTime = Date()
    var result = base
    var frontier = base
    while frontier.count > 0 {
        frontier = frontier.map(expand).joined().filter(good)
        result += frontier
        print("Fast least fixed point time elapsed: \(startTime.millisecondsToPresent)")
    }
    let answer = result.map(project)
    print("Fast least fixed point total time: \(startTime.millisecondsToPresent)")
    print("\(answer.count) elements generated.")
    return answer
}

// Grows the list by expanding objects according to their priority
// DOES NOT ADD the projection of the base
func priorityBasedFixedPoint<T, U>(queueTable: QueueTable<T>, expand: (T) -> [T], priority: (T) -> Int, priorityMax: Int, batchSize: Int, timeLimitInMilliseconds: Int, project: (T) -> U) -> QueueTable<U> {
    let allNewObjects = QueueTable<U>()
    let startTime = Date()
    MAIN: while startTime.millisecondsToPresent < timeLimitInMilliseconds  && queueTable.currentPriority <= priorityMax {
        for _ in 0...batchSize {
            guard queueTable.hasNext else { break MAIN }
            let object = queueTable.next()!
            let newObjects = expand(object)
            for newObject in newObjects {
                let p = priority(newObject)
                allNewObjects.add(project(newObject), priority: p)
                queueTable.add(newObject, priority: p)
            }
        }
    }
    return allNewObjects
}

func priorityBasedFixedPoint<T, U>(base: [T], expand: (T) -> [T], priority: (T) -> Int, priorityMax: Int, batchSize: Int, timeLimitInMilliseconds: Int, project: (T) -> U) -> (QueueTable<T>, QueueTable<U>) {
    let queueTable = QueueTable<T>()
    for object in base {
        queueTable.add(object, priority: priority(object))
    }
    let newTable = priorityBasedFixedPoint(queueTable: queueTable, expand: expand, priority: priority, priorityMax: priorityMax, batchSize: batchSize, timeLimitInMilliseconds: timeLimitInMilliseconds, project: project)
    for object in base {
        newTable.add(project(object), priority: priority(object))
    }
    return (queueTable, newTable)
}




