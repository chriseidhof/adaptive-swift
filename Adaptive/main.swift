// Implementation of Adaptive Functional Programming
// https://sites.google.com/site/umutacar/publications/popl2002.pdf?attredirects=1

import Cocoa

func test() {
    let adaptive = Adaptive()
    let (l, last) = adaptive.fromSequence([4,3,2])
    let l2 = adaptive.map(l, { (value: Int) -> Int in
        print("incrementing \(value)")
        return value + 1
    })
    let sum = adaptive.reduce(l2, initial: 0, +)
    sum.read { print("current sum: \($0)") }

    
    adaptive.propagate()
    last.write(AList<Int>.cons(7, adaptive.new(value: .empty)))
    adaptive.propagate()

}

test()
