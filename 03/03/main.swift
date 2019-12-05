import Foundation

struct Point: Hashable {
    var x: Int
    var y: Int
}

func tracePath<T>(_ p: T) -> Dictionary<Point, Int> where T: StringProtocol {
    let instructions = p.split(separator: ",")
    var wire = Dictionary<Point, Int>(minimumCapacity: instructions.count)
    var currentPos = Point(x: 0, y: 0)
    var steps = 0
    for instruction in instructions {
        let direction = instruction.first!
        let amount = Int(instruction[instruction.index(after: instruction.startIndex)...])!
        var xOffset = 0
        var yOffset = 0
        switch (direction)
        {
        case "R":
            xOffset = 1;
            yOffset = 0;
            break;
        case "D":
            xOffset = 0;
            yOffset = -1;
            break;
        case "L":
            xOffset = -1;
            yOffset = 0;
            break;
        case "U":
            xOffset = 0;
            yOffset = 1;
            break;
        default:
            break;
        }
        for _ in 1...amount {
            currentPos.x += xOffset
            currentPos.y += yOffset
            steps += 1
            if wire[currentPos] == nil {
                wire[currentPos] = steps
            }
        }
    }
    return wire
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

let wires = fileContents.split(separator: "\n")
let wire1 = tracePath(wires[0])
let wire2 = tracePath(wires[1])

let intersections = wire1.filter{ wire2.keys.contains($0.key)}
let part1 = intersections.map {abs($0.key.x) + abs($0.key.y)}.min()!
let part2 = intersections.map {$0.value + wire2[$0.key]!}.min()!

print(part1)
print(part2)
