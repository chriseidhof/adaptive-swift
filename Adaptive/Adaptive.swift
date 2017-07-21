//
//  Adaptive.swift
//  Adaptive
//
//  Created by Chris Eidhof on 21.07.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation

struct T: Comparable {
    static func <(lhs: T, rhs: T) -> Bool {
        return lhs.time < rhs.time
    }
    
    static func ==(lhs: T, rhs: T) -> Bool {
        return lhs.time == rhs.time
    }
    
    fileprivate let time: Double
}

struct Time {
    private var backing: SortedArray<T> = SortedArray(unsorted: [T(time: 0.0)])
    var initial: T {
        return T.init(time: 0)
    }
    
    func compare(l: T, r: T) -> Bool {
        return l.time < r.time
    }
    
    mutating func insert(after: T) -> T {
        let index = backing.index(of: after)!
        let newTime: T
        let nextIndex = backing.index(after: index)
        if nextIndex == backing.endIndex {
            newTime = T(time: after.time + 0.1)
        } else {
            let nextValue = backing[nextIndex]
            newTime = T(time: (after.time + nextValue.time)/2)
        }
        backing.insert(newTime)
        return newTime
    }
    
    mutating func delete(between from: T, and to: T) {
        assert(from.time <= to.time)
        backing.remove(where: { $0 > from && $0 < to})
    }
    
    func contains(t: T) -> Bool {
        return backing.contains(t)
    }
}

struct Edge: Comparable {
    static func <(lhs: Edge, rhs: Edge) -> Bool {
        if lhs.timeSpan.start < rhs.timeSpan.start { return true }
        return rhs.timeSpan.start < rhs.timeSpan.start
    }
    
    static func ==(lhs: Edge, rhs: Edge) -> Bool {
        return lhs.timeSpan == rhs.timeSpan // not sure if this makes sense (we're not comparing reader)
    }
    
    let reader: () -> ()
    let timeSpan: (start: T, end: T)
}

final class Node<A> {
    fileprivate var value: () -> A
    var write: (A) -> ()
    var outEdges: [Edge]
    unowned let adaptive: Adaptive
    
    init(adaptive: Adaptive, value: @escaping () -> A, write: @escaping (A) -> (), outEdges: [Edge] = []) {
        self.adaptive = adaptive
        self.value = value
        self.write = write
        self.outEdges = outEdges
    }
    
    func read(_ f: @escaping (A) -> ()) {
        adaptive.read(node: self, f)
    }
}



typealias PriorityQueue = SortedArray<Edge>

final class Adaptive {
    var time: Time = Time()
    var currentTime: T
    var queue: PriorityQueue
    
    init() {
        currentTime = time.initial
        queue = SortedArray(unsorted: [])
    }
    
    func new<A>(compare: @escaping (A, A) -> Bool, _ f: @escaping (Node<A>) -> ()) -> Node<A> {
        var node = Node<A>(adaptive: self, value: { fatalError() }, write: { _ in fatalError() })
        func change(time: T, value: A) {
            if compare(value, node.value()) { return }
            node.value = { value }
            for edge in node.outEdges {
                queue.insert(edge)
            }
            currentTime = time
        }
        node.write = { value in
            node.value = { value }
            self.currentTime = self.time.insert(after: self.currentTime)
            let theTime = self.currentTime
            node.write = { change(time: theTime, value: $0) }
        }
        f(node)
        return node
    }
    
    fileprivate func read<A>(node: Node<A>, _ f: @escaping (A) -> ()) -> () {
        currentTime = time.insert(after: currentTime)
        let start = currentTime
        func run() {
            f(node.value())
            node.outEdges.append(Edge(reader: run, timeSpan: (start: start, end: currentTime)))
        }
        run()
    }
    
    func propagate() {
        let theTime = currentTime
        while !queue.isEmpty {
            let edge = self.queue.remove(at: 0)
            guard time.contains(t: edge.timeSpan.start) else {
                continue
            }
            
            time.delete(between: edge.timeSpan.start, and: edge.timeSpan.end)
            currentTime = edge.timeSpan.start
            edge.reader()
        }
        currentTime = theTime
    }
}

extension Adaptive {
    func new<A: Equatable>(transform: @escaping (Node<A>) -> ()) -> Node<A> {
        return new(compare: ==, transform)
    }
    
    func new<A: Equatable>(value: A) -> Node<A> {
        return new(compare: ==) { node in
            node.write(value)
        }
    }
}

indirect enum AList<A>: Equatable {
    case empty
    case cons(A, Node<AList<A>>)
    
    static func ==(lhs: AList, rhs: AList) -> Bool {
        if case .empty = lhs, case .empty = rhs { return true }
        return false
        
    }
}
extension Adaptive {
    func fromSequence<S, A>(_ sequence: S) -> (Node<AList<A>>, Node<AList<A>>) where S: Sequence, S.Iterator.Element == A {
        let tail: Node<AList<A>> = new(value: .empty)
        var result: Node<AList<A>> = tail
        for item in sequence {
            result = new(value: .cons(item, result))
        }
        return (result, tail)
    }
    
    func map<A, B>(_ list: Node<AList<A>>, _ transform: @escaping (A) -> B) -> Node<AList<B>> {
        func mapH(_ list: Node<AList<A>>, destination: Node<AList<B>>) {
            list.read {
                switch $0 {
                case .empty:
                    destination.write(.empty)
                case let .cons(el, tail):
                    destination.write(.cons(transform(el), self.new(transform: { mapH(tail, destination: $0)})))
                }
            }
        }
        return new { mapH(list, destination: $0) }
    }
    
    func reduce<A, Result>(_ list: Node<AList<A>>, initial: (Result), _ transform: @escaping (Result, A) -> Result) -> Node<Result> where Result: Equatable {
        func reduceH(_ list: Node<AList<A>>, intermediate: Result, destination: Node<Result>) {
            list.read {
                switch $0 {
                case .empty:
                    destination.write(intermediate)
                case let .cons(el, tail):
                    reduceH(tail, intermediate: transform(intermediate, el), destination: destination)
                }
            }
        }
        return new { reduceH(list, intermediate: initial, destination: $0) }
    }
}
