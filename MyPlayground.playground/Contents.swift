//: Playground - noun: a place where people can play

var a = [1: [2, 3]]

a[1]

a[1]?.append(4)

a[1]

var oldArray = a[1]!

oldArray.append(5)

a[1]

if var array = a[1] {
    array.append(6)
}

a[1]

let add1: Int -> Int  = { $0 + 1 }

add1(2)

let add2: (Int) -> Int = { $0 + 2 }

add2(2)

let add3: (Int -> Int) = {$0 + 3 }

add3(3)

func wtf<A, B>(input: A, function: A -> B) -> B {
    return function(input)
}

wtf(5, function: add2)




