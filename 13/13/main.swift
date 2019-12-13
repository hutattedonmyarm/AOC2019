import Foundation

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

func draw(tiles: [Point: Tile], score: Int) {
    let maxX = tiles.max { $0.key.x < $1.key.x }!.key.x
    let maxY = tiles.max { $0.key.y < $1.key.y }!.key.y
    
    print("Score: \(score) - \(maxY)")
    for y in 0...maxY {
        var line = ""
        for x in 0...maxX {
            let point = Point(x: x, y: y)
            let tile = tiles[point] ?? .empty
            line += tile.description
        }
        print(line)
    }
    usleep(50000)
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
var score = -1
var inputQueue = Queue(initialValue: -1)
let ips = [0, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
for i in ips {
    inputQueue.enqueue(i)
}

/*

If the joystick is in the neutral position, provide 0.
If the joystick is tilted to the left, provide -1.
If the joystick is tilted to the right, provide 1.
The arcade cabinet also has a segment display capable of showing a single number that represents the player's current score. When three output instructions specify X=-1, Y=0, the third output instruction is not a tile; the value instead specifies the new score to show in the segment display. For example, a sequence of output values like -1,0,12345 would show 12345 as the player's current score.
*/

let input: Input = {
    draw(tiles: tiles, score: score)
    //let str = readLine()!
    //let inp = Int(str)
    //return inp
    
    //return inputQueue.dequeue()
    
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
