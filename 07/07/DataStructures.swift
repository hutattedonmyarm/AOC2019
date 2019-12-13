import Foundation

public class Node<T> {
    var value: T
    var next: Node<T>?
    weak var previous: Node<T>?

    init(value: T) {
        self.value = value
    }
}

public class LinkedList<T>: CustomStringConvertible {
    private var head: Node<T>?
    private var tail: Node<T>?

    public var description: String {
        var text = "["
        var node = head;
        while let n = node {
            text += "\(n.value)"
            node = n.next
            if node != nil { text += ", " }
        }
        return text + "]"
    }
    
    public var isEmpty: Bool {
        return head == nil
    }

    public var first: Node<T>? {
        return head
    }

    public var last: Node<T>? {
        return tail
    }
    
    public func append(value: T) {
        let newNode = Node(value: value)
        if let tailNode = tail {
            newNode.previous = tailNode
            tailNode.next = newNode
        } else {
            head = newNode
        }
       
        tail = newNode
    }
    
    public func remove(node: Node<T>) -> T {
        let prev = node.previous
        let next = node.next

        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        next?.previous = prev

        if next == nil {
            tail = prev
        }

        node.previous = nil
        node.next = nil

        return node.value
    }
    
    public func remove(at index: Int) -> T? {
        guard let node = nodeAt(index: index) else { return nil }
        return remove(node: node)
    }
    
    public func nodeAt(index: Int) -> Node<T>? {
        guard index >= 0 else { return nil }
        var node = head
        var i = index
        while let n = node {
          if i == 0 { return n }
          i -= 1
          node = n.next
        }
        return node
    }
    
    public func clear() {
        head = nil
        tail = nil
    }
}

public struct Queue<T>: CustomStringConvertible {
    private var list = LinkedList<T>()
    public var description: String { list.description }
    
    init() {
    }
    
    init(initialValue: T) {
        enqueue(initialValue)
    }
    
    public mutating func enqueue(_ element: T) {
        list.append(value: element)
    }
    
    public mutating func dequeue() -> T? {
        guard !list.isEmpty, let element = list.first else { return nil }
        _ = list.remove(node: element)
        return element.value
    }
    
    public var isEmpty: Bool {
        return list.isEmpty
    }
}

public struct Point: Hashable, Equatable {
    let x: Int
    let y: Int
}
