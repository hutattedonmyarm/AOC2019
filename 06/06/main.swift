import Foundation

class Node: CustomStringConvertible, Equatable {
  var left: Node? = nil
  var right: Node? = nil
  let value: String

  init(_ value: String) {
    self.value = value
  }
  func append(_ n: Node) {
    if left == nil {
      left = n
    } else {
      right = n
    }
  }
  public var description: String {
    return "\(value) (\(left?.value ?? "_"), \(right?.value ?? "_"))"
  }
  static func == (lhs: Node, rhs: Node) -> Bool {
    return lhs.value == rhs.value
  }
}

func getPlanet(_ value: String, planets: inout [Node]) -> Node {
  var p = planets.first {$0.value == value}
  if p == nil {
    p = Node(value)
    planets.append(p!)
  }
  return p!
}

func buildTree(map: [String]) -> (Node, [Node]) {
  var knownPlanets = [Node]()
  var com: Node? = nil
  for line in map {
    let orbit = line.split(separator: ")")
    let p1 = orbit[0].description
    let p2 = orbit[1].description
    let planet1 = getPlanet(p1, planets: &knownPlanets)
    let planet2 = getPlanet(p2, planets: &knownPlanets)
    planet1.append(planet2)
    if (com == nil && p1 == "COM") {
      com = planet1
    }
  }
  return (com!, knownPlanets)
}


func pathToNode(root r: Node?, path: inout [Node], value: String) -> Bool {
  guard let root = r else {
    return false
  }
  path.append(root)
  if root.value == value {
    return true
  }

  if let left = root.left, pathToNode(root: left, path: &path, value: value) {
    return true
  }
  if let right = root.right, pathToNode(root: right, path: &path, value: value) {
    return true
  }
  path.removeLast()
  return false
}

func distance(root: Node, from: String, to: String) -> Int {
  var path1 = [Node]()
  _ = pathToNode(root: root, path: &path1, value: from)

  var path2 = [Node]()
  _ = pathToNode(root: root, path: &path2, value: to)

  var dist = 0
  while dist < path1.count && dist < path2.count {
    if path1[dist] != path2[dist] {
      break
    }
    dist += 1
  }
  return path1.count + path2.count - 2*dist
}

func calcOrbits(_ rawOrbits: [String]) -> Int {
    var map = [String: String]()
    
    for orbitLine in rawOrbits {
        let o = orbitLine.split(separator: ")")
        map[o[1].description] = o[0].description
    }
    
    var numOrbits = 0
    for entry in map {
        numOrbits += 1
        var k = entry.value
        while let v = map[k] {
            numOrbits += 1
            k = v
        }
    }
    return numOrbits
}

func go(input: String) {
    let lines = input.split(separator: "\n").map {$0.description}
    print(calcOrbits(lines))
    let (com, _) = buildTree(map: lines)
    let jumps = distance(root: com, from: "SAN", to: "YOU")
    print(jumps - 2)
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

go(input: ro)
go(input: fileContents)
