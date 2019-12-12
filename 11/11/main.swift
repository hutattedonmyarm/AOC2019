import Foundation

public typealias Row = [Paint]
public typealias Grid = [Row]

public struct Point: Hashable {
    let column: Int
    let row: Int
}
public enum Direction {
    case up
    case right
    case down
    case left
}

public enum Paint: CustomStringConvertible {
    case black
    case white
    
    func toInt() -> Int {
        switch self {
        case .black:
            return 0
        case .white:
            return 1
        }
    }
    
    init?(output: Int) {
        if output == 0 {
            self = .black
        } else if output == 1 {
            self = .white
        } else {
            return nil
        }
    }
    
    public var description: String {
        switch self {
        case .black:
            return " "
        case .white:
            return "#"
        }
    }
}

public struct InfinityGrid: CustomStringConvertible {
    private var currentPosition: Point
    public private(set) var visited: [Point: Paint]
    private static let defaultColor = Paint.black
    
    public init(startColor: Paint) {
        self.currentPosition = Point(column: 0, row: 0)
        self.visited = [Point: Paint]()
        self.visited[currentPosition] = startColor
    }
    
    public init() {
        self.init(startColor: InfinityGrid.defaultColor)
    }
    
    mutating func moveRight() -> Paint {
        currentPosition = Point(column: self.currentPosition.column+1, row: self.currentPosition.row)
        return detect()
    }
    
    mutating func moveDown() -> Paint {
        currentPosition = Point(column: self.currentPosition.column, row: self.currentPosition.row+1)
        return detect()
    }
    
    mutating func moveLeft() -> Paint {
        currentPosition = Point(column: self.currentPosition.column-1, row: self.currentPosition.row)
        return detect()
    }
    
    mutating func moveUp() -> Paint {
        currentPosition = Point(column: self.currentPosition.column, row: self.currentPosition.row-1)
        return detect()
    }
    
    mutating func detect() -> Paint {
        if let paint = visited[currentPosition] {
            return paint
        } else {
            self.visited[currentPosition] = InfinityGrid.defaultColor
            return InfinityGrid.defaultColor
        }
    }
    
    mutating func paint(withColor color: Paint) {
        self.visited[currentPosition] = color
    }
    
    public var description: String {
        let maxCol = visited.max { $0.key.column < $1.key.column }!.key.column
        let minCol = visited.min { $0.key.column < $1.key.column }!.key.column
        let maxRow = visited.max { $0.key.row < $1.key.row }!.key.row
        let minRow = visited.min { $0.key.row < $1.key.row }!.key.row
        var str = ""
        for col in minCol...maxCol {
            for row in (minRow...maxRow).reversed() {
                let point = Point(column: col, row: row)
                var color = Paint.black
                if let painted = visited[point] {
                    color = painted
                }
                str += color.description
            }
            str += "\n"
        }
        return str
    }
}

func go(input: String) {
    let memory = IOProgram.parse(program: input)
    var panels = InfinityGrid()
    var direction = Direction.up
    let input = {
        panels.detect().toInt()
    }
    var shouldPaint = true
    let output: (Int) -> Void = {
        if shouldPaint {
            panels.paint(withColor: Paint(output: $0)!)
        } else {
            switch direction {
            case .down where $0 == 0:
                direction = .right
                _ = panels.moveRight()
            case .down where $0 == 1:
                direction = .left
                _ = panels.moveLeft()
            case .left where $0 == 0:
                direction = .down
                _ = panels.moveDown()
            case .left where $0 == 1:
                direction = .up
                _ = panels.moveUp()
            case .up where $0 == 0:
                direction = .left
                _ = panels.moveLeft()
            case .up where $0 == 1:
                direction = .right
                _ = panels.moveRight()
            case .right where $0 == 0:
                direction = .up
                _ = panels.moveUp()
            case .right where $0 == 1:
                direction = .down
                _ = panels.moveDown()
            default:
                fatalError("Unknown output")
            }
        }
        shouldPaint = !shouldPaint

    }
    let robot = IOProgram(program: memory, input: input, output: output)
    robot.run()
    print(panels.visited.count)
    
    panels = InfinityGrid(startColor: .white)
    let robot2 = IOProgram(program: memory, input: input, output: output)
    robot2.run()
    print(panels)
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

go(input: fileContents)
