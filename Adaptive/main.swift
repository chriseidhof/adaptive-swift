// Implementation of Adaptive Functional Programming
// https://sites.google.com/site/umutacar/publications/popl2002.pdf?attredirects=1

import Cocoa

struct Person: Equatable {
    var name: String
    
    static func ==(lhs: Person, rhs: Person) -> Bool {
        return lhs.name == rhs.name
    }
}

//final class TableViewApp {
//
//    private let adaptive = Adaptive()
//    private let people: Node<AdaptiveArray<Person>>
//    private let changePeople: (Array<Person>.Change) -> ()
//
//    init() {
//        let (p1, cp) = adaptive.array(initial: Array<Person>())
//        people = p1
//        changePeople = cp
//
//    }
//
//    enum Message {
//        case append(Person)
//    }
//
//    func send(message: Message) {
//        switch message {
//        case .append(let person):
//            changePeople(.append(person))
//        }
//    }
//}
//
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

    let (arr, change) = adaptive.array(initial: [1,2,3,4,5])
    arr.read { result in
        print("changes: \(result.changes)")
    }
    change(.insert(element: 0, at: 1))
    adaptive.propagate()
//    let result = changed.map() { arr in
//        adaptive.reduce2(compare: ==, list: arr.changes, initial: arr.initial, transform: { (i: [Int], change: Array<Int>.Change) -> [Int] in
//            var x = i
//            x.apply(change: change)
//            print("applying: \(change)")
//            return i
//    })
//    }
//    result.read { r in
//        print("array: \(r)")
//    }


}
//
//test()

