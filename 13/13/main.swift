import Foundation

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

func draw(tiles: [Point: Tile], score: Int) {
    let width = tiles.max { $0.key.x < $1.key.x }!.key.x
    let height = tiles.max { $0.key.y < $1.key.y }!.key.y
    
    let scoreFormat = String(format: "%05d", score)
    var scoreLabel = " Score: \(scoreFormat) "
    var scoreWidth = scoreLabel.count
    if (1+width - scoreWidth) % 2 != 0 {
        scoreLabel.append(" ")
        scoreWidth += 1
    }
    let chars = [Character](repeating: "-", count: (1+width - scoreWidth) / 2)
    let filler = String(chars)
    
    print("\(filler)\(scoreLabel)\(filler)")
    for row in 0...height {
        print((0...width).map { (tiles[Point(x: $0, y: row)] ?? .empty).description }.joined())
    }
    usleep(40000)
}

enum Tile: Int, Hashable, CustomStringConvertible {
    case empty = 0
    case wall
    case block
    case horizontal
    case ball
    
    public var description: String {
        switch self {
        case .empty:
            return " "
        case .wall:
            return "X"
        case .block:
            return "#"
        case .horizontal:
            return "-"
        case .ball:
            return "O"
        }
    }
}

var posX: Int? = nil
var posY: Int? = nil
var tiles = [Point: Tile]()
var score = 0

let input: Input = {
    draw(tiles: tiles, score: score)
    let ballPos = tiles.first { $1 == .ball }!
    let paddlePos = tiles.first { $1 == .horizontal }!
    return ballPos.key.x == paddlePos.key.x ? 0 : ballPos.key.x < paddlePos.key.x ? -1 : 1
}
let output: Output = {
    if posX == nil {
        posX = $0
    } else if posY == nil {
        posY = $0
    } else if posX == -1 && posY == 0 {
        score = $0
        posX = nil
        posY = nil
        draw(tiles: tiles, score: score)
    } else {
        tiles[Point(x: posX!, y: posY!)] = Tile(rawValue: $0)!
        posX = nil
        posY = nil
    }
}



let gameCode = IOProgram.parse(program: fileContents)
let game = IOProgram(program: gameCode, input: input, output: output)
game.setMemory(at: 0, to: 2)
game.run()
print(game.state)

let blocks = tiles.filter { $0.value == .block }
print(blocks.count)
print(score)
