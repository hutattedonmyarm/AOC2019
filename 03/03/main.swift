import Foundation

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

var originalInput = fileContents.split(separator: "\n").map { $0.split(separator: ",")}
//originalInput = "R75,D30,R83,U83,L12,D49,R71,U7,L72\nU62,R66,U55,R34,D71,R55,D58,R83".split(separator: "\n").map { $0.split(separator: ",")}

struct Point: Hashable {
    var x: Int
    var y: Int
}

var coords = Set<Point>()
var currentPos = Point(x: 0, y: 0)
var intersections = Set<Point>()
var wireCoords = Set<Point>()

for wire in originalInput {
    currentPos = Point(x: 0, y: 0)
    wireCoords = Set<Point>()
    for instruction in wire {
        let direction = instruction.first!
        let amount = Int(instruction[instruction.index(instruction.startIndex, offsetBy: 1)..<instruction.endIndex])!
        switch direction {
        case "R":
            for _ in 1...amount {
                currentPos.x += 1
                
                if coords.contains(currentPos) && !wireCoords.contains(currentPos) {
                    intersections.insert(currentPos)
                } else {
                    coords.insert(currentPos)
                    wireCoords.insert(currentPos)
                }
            }
        case "D":
            for _ in 1...amount {
                currentPos.y += 1
                if coords.contains(currentPos) && !wireCoords.contains(currentPos) {
                    intersections.insert(currentPos)
                } else {
                    coords.insert(currentPos)
                    wireCoords.insert(currentPos)
                }
            }
        case "L":
            for _ in 1...amount {
                currentPos.x -= 1
                if coords.contains(currentPos) && !wireCoords.contains(currentPos) {
                    intersections.insert(currentPos)
                } else {
                    coords.insert(currentPos)
                    wireCoords.insert(currentPos)
                }
            }
        case "U":
            for _ in 1...amount {
                currentPos.y -= 1
                if coords.contains(currentPos) && !wireCoords.contains(currentPos) {
                    intersections.insert(currentPos)
                } else {
                    coords.insert(currentPos)
                    wireCoords.insert(currentPos)
                }
            }
        default:
            break
        }
    }
}

/*
for y in -100...100 {
    for x in 0...210 {
        let s = x == 0 && y == 0 ? "o" : coords.contains(Point(x: x, y: y)) ? "x" : "."
        print(s, terminator: "")
    }
    print("")
}*/

let m = intersections.map {abs($0.x) + abs($0.y)}.min()!
print(m)
