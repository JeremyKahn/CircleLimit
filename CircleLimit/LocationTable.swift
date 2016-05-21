//
//  LocationTable.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 1/6/16.
//  Copyright © 2016 Jeremy Kahn. All rights reserved.
//

import Foundation

// A class of objects each with a Location, with a way to generate the neighboring Location's
// Any two things that are close to each other must have Location's that are equal or are neighbors
public protocol Locatable {
    
    associatedtype  Location : Hashable
    
    var location : Location {get}
    
    static func neighbors(_: Location) -> [Location]
}

public protocol Matchable {
 
    func matches(y: Self) -> Bool
    
}


// You can look up a Locatable object in a LocationTable, and it will only search for it in its Location or neighboring Location's
// This works well for a dictionary where the keys are points in a manifold, and there may have been slight errors in the keys introduced by computation
public class LocationTable<T: Locatable> {
    
    var table : Dictionary<T.Location, Array<T>> = Dictionary()
    
    var count = 0
    
    public init() {}
    
    public func add(entries: [T]) {
        for E in entries {
            add(E)
        }
        count += entries.count
    }
    
    public func add(E : T) {
        let l = E.location
        if var tempArray = table[l] {
            tempArray.append(E)
            table.updateValue(tempArray, forKey: l)
        } else {
            table.updateValue([E], forKey: l)
        }
        count += 1
    }
    
    public func addIfNotMatching(E: T, match: (T, T) -> Bool) {
        let potentialMatches = arrayForNearLocation(E.location)
        for potentialMatch in potentialMatches {
            if match(E, potentialMatch) {
                return
            }
        }
        add(E)
    }
    
    public func addNonMatchingEntries(entries: [T], match: (T, T) -> Bool) {
        for E in entries {
            addIfNotMatching(E, match: match)
        }
    }
    
    public func arrayForNearLocation(l: T.Location) -> [T] {
        var array : [T] = []
        for l in  T.neighbors(l) {
            if let newArray = table[l] {
                array += newArray
            }
        }
        return array
    }
    
    public var arrayForm : [T] {
        var array : [T] = []
        for (_, list) in table {
            array += list
        }
        return array
    }
    
}

// Returns an array of values for a given key--you can't get rid of things or replace them
public class WeakLocationDictionary<Key: protocol<Locatable, Matchable>, Value> {
    
    private var dictionary: Dictionary<Key.Location, Array<(Key, Value)>> = Dictionary()
    
    var keys: [Key] {
        let keyValuePairs = dictionary.map({$0.1}).flatten()
        return keyValuePairs.map({$0.0})
    }
    
    subscript (key: Key) -> [Value] {
        let neighbors = Key.neighbors(key.location)
        let potentialMatches = dictionary.valuesForKeys(neighbors).flatten()
        var result: [Value] = []
        for (enteredKey, value) in potentialMatches {
            if enteredKey.matches(key) {
                result.append(value)
            }
        }
        return result
    }
    
    func addValue(value: Value, forKey key: Key)  {
        let l = key.location
        if dictionary[l] != nil {
            dictionary[l]!.append((key, value))
        } else {
            dictionary[l] = [(key, value)]
        }
    }

}

// this requires that a is neighbor of b whenever a.matches(b)
public class LocationDictionary<Key: protocol<Locatable, Matchable>, Value> {
    
    var dictionary: Dictionary<Key.Location, Array<(Key, Value)>> = Dictionary()
    
    subscript (key: Key) -> Value? {
        let neighbors = Key.neighbors(key.location)
        let potentialMatches = dictionary.valuesForKeys(neighbors).flatten()
        for (enteredKey, value) in potentialMatches {
            if enteredKey.matches(key) {
                return value
            }
        }
        return nil
    }
    
    
    func updateValue(value: Value, forKey key: Key)  -> Value? {
        let neighbors = Key.neighbors(key.location)
        for neighbor in neighbors {
            if let list = dictionary[neighbor] {
                for i in 0..<list.count {
                    if list[i].0.matches(key) {
                        let oldValue = list[i].1
                        dictionary[neighbor]![i] = (key, value)
                        return oldValue
                    }
                }
            }
            
        }
        if dictionary[key.location] != nil {
            dictionary[key.location]?.append((key, value))
        } else {
            dictionary[key.location] = [(key, value)]
        }
        return nil
    }
    
}

public func leastFixedPoint<T: Locatable>(base: [T], map: T -> [T], match: (T, T) -> Bool) -> [T] {
    return leastFixedPoint(base, map: map, match: match, maxTime: 1.0)
}

public func leastFixedPoint<T: Locatable>(base: [T], map: T -> [T], match: (T, T) -> Bool, maxTime: Double) -> [T] {
    print("LFP time allotted: " + maxTime.nice)
    let startTime = NSDate()
    let table = LocationTable<T>()
    table.add(base)
    var frontier = base
    while frontier.count > 0 && secondsSince(startTime) < maxTime {
        let potentialNewFrontier: [T] = frontier.reduce([], combine: {$0 + map($1)})
        // frontier is the new frontier
        frontier = []
        filter: for x in potentialNewFrontier {
            for U in table.arrayForNearLocation(x.location) {
                if match(x, U) {
                    continue filter
                }
            }
            frontier.append(x)
        }
        table.add(frontier)
    }
    print("LFP time taken: " + secondsSince(startTime).nice)
    return table.arrayForm
}




// This works when equivalent(A, B) implies that A is a neighbor to B
public func minimumRepresentatives<T, U: protocol<Locatable, Matchable>>(list: [T], lessThan: (T, T) -> Bool, projection: T -> U) -> [T] {
    let d = WeakLocationDictionary<U, T>()
    for x in list {
        d.addValue(x, forKey: projection(x))
    }
    var result: [T] = []
    for x in d.keys {
        let values = d[x]
        let minValue = values.reduce(values.first!, combine: {lessThan($0, $1) ? $0 : $1})
        result.append(minValue)
    }
    return result
}


