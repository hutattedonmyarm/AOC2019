import Foundation

extension String {
    mutating func replace<T>(atIndex index: Int, with newString: T) where T: StringProtocol {
        let ra = self.index(self.startIndex, offsetBy: index)
        self.replaceSubrange(ra...ra, with: newString)
    }
}

struct Point: Hashable {
    let row: Int
    let column: Int
}

func atan2(y: Double, x: Double) -> Double? {
    var atan2: Double? = nil
    if x > 0 {
        atan2 = atan(y / x)
    } else if x < 0 && y >= 0 {
        atan2 = atan(y / x) + Double.pi
    } else if x < 0 && y < 0 {
        atan2 = atan(y / x) - Double.pi
    } else if x == 0 && y > 0 {
        atan2 = Double.pi / 2.0
    } else if x == 0 && y < 0 {
        atan2 = -Double.pi / 2.0
    }
    return atan2
}

func getVisible(asteroids: [[Bool]], currentRow: Int, currentColumn: Int, width: Int) -> [Double: (Int, Int)] {
    var n = 1
    var blocked = [Double: (Int, Int)]()
    while !(currentRow-n < 0 && currentRow >= asteroids.count-n && currentColumn-n < 0 && currentColumn >= width-n) {
        var cur = 0
        for tmpR in currentRow-n...currentRow+n {
            for tmpC in currentColumn-n...currentColumn+n {
                if (tmpR == currentRow && tmpC == currentColumn) || tmpR < 0 || tmpC < 0 || tmpR >= asteroids.count || tmpC >= asteroids[0].count {
                    continue
                }
                if !(tmpR == currentRow-n || tmpR == currentRow+n || tmpC == currentColumn-n || tmpC == currentColumn+n) {
                    continue
                }
                if asteroids[tmpR][tmpC] {
                    let y = Double(tmpR-currentRow)
                    let x = Double(tmpC-currentColumn)
                    var angle = atan2(y: y, x: x)! + 0.5 * Double.pi
                    if angle < 0 {
                        angle += 2.0 * Double.pi
                    }
                    let isBlocked = blocked[angle] != nil
                    if !isBlocked {
                        cur += 1
                        blocked[angle] = (tmpR-currentRow, tmpC-currentColumn)
                    }
                }
            }
        }
        if cur == 0 {
            // Skip remaining
            break
        }
        n += 1
    }
    return blocked
}

enum ANSIColors: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case reset = "\u{001b}[0m"

    func name() -> String {
        switch self {
        case .black: return "Black"
        case .red: return "Red"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .magenta: return "Magenta"
        case .cyan: return "Cyan"
        case .white: return "White"
        case .reset: return "Default"
        }
    }

    static func all() -> [ANSIColors] {
        return [.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white, .reset]
    }
}

func + (left: ANSIColors, right: String) -> String {
    return left.rawValue + right
}

func gcd(_ a:Int, _ b:Int) -> Int {
    if a == b {
        return a
    }
    else {
        if a > b {
            return gcd(a-b, b)
        }
        else {
            return gcd(a, b-a)
        }
    }
}

func printField(asteroids: [[Bool]], station: Point, lastBlown: Point?, projectilePositions: ArraySlice<Point>?, projectiles:ArraySlice<Character?>?) {
    var a = asteroids.map { $0.map {$0 ? "#" : "."}.joined() }
    
    var r = a[a.startIndex.advanced(by: station.row)]
    r.replace(atIndex: station.column, with: "\(ANSIColors.cyan.rawValue)X\(ANSIColors.reset.rawValue)")
    a[a.startIndex.advanced(by: station.row)] = r
    
    if let projectilePositions = projectilePositions, let projectiles = projectiles {
        for (idx, currentProjectile) in projectilePositions.enumerated() {
            let projectile = projectiles[projectiles.startIndex.advanced(by: idx)]
            if let lastBlown = lastBlown, currentProjectile != lastBlown {
                r = a[a.startIndex.advanced(by: lastBlown.row)]
                
                r.replace(atIndex: lastBlown.column, with: "\(ANSIColors.yellow.rawValue)O\(ANSIColors.reset.rawValue)")
                a[a.startIndex.advanced(by: lastBlown.row)] = r
            }
            if currentProjectile != lastBlown {
                r = a[a.startIndex.advanced(by: currentProjectile.row)]
                
                let indexOffset = (currentProjectile.row == station.row && currentProjectile.column > station.column && currentProjectile.column < station.column + 6
                    || currentProjectile.row == lastBlown?.row && currentProjectile.column > lastBlown!.column && currentProjectile.column < lastBlown!.column + 6) ? 11 : 0
                r.replace(atIndex: currentProjectile.column+indexOffset, with: "\(ANSIColors.red.rawValue)\(projectile ?? "o")\(ANSIColors.reset.rawValue)")
                
                
                //r.replace(atIndex: currentProjectile.column, with: "o")
                a[a.startIndex.advanced(by: currentProjectile.row)] = r
            }
            if currentProjectile == lastBlown {
                r = a[a.startIndex.advanced(by: currentProjectile.row)]
                r.replace(atIndex: currentProjectile.column, with: "\(ANSIColors.red.rawValue)O\(ANSIColors.reset.rawValue)")
                //r.replace(atIndex: currentProjectile.column, with: "o")
                a[a.startIndex.advanced(by: currentProjectile.row)] = r
            }
        }
    }
    print(a.joined(separator: "\n"))
}

func printField(asteroids: [[Bool]], station: Point, lastBlown: Point?, projectilePosition: Point?, projectile: Character?) {
    var a = asteroids.map { $0.map {$0 ? "#" : "."}.joined() }
    
    var r = a[a.startIndex.advanced(by: station.row)]
    r.replace(atIndex: station.column, with: "\(ANSIColors.cyan.rawValue)X\(ANSIColors.reset.rawValue)")
    a[a.startIndex.advanced(by: station.row)] = r
    
    if let lastBlown = lastBlown, projectilePosition != lastBlown {
        r = a[a.startIndex.advanced(by: lastBlown.row)]
        
        r.replace(atIndex: lastBlown.column, with: "\(ANSIColors.yellow.rawValue)O\(ANSIColors.reset.rawValue)")
        a[a.startIndex.advanced(by: lastBlown.row)] = r
    }
    if let currentProjectile = projectilePosition, projectilePosition != lastBlown {
        r = a[a.startIndex.advanced(by: currentProjectile.row)]
        
        let indexOffset = (currentProjectile.row == station.row && currentProjectile.column > station.column && currentProjectile.column < station.column + 6
            || currentProjectile.row == lastBlown?.row && currentProjectile.column > lastBlown!.column && currentProjectile.column < lastBlown!.column + 6) ? 11 : 0
        r.replace(atIndex: currentProjectile.column+indexOffset, with: "\(ANSIColors.red.rawValue)\(projectile ?? "o")\(ANSIColors.reset.rawValue)")
        
        
        //r.replace(atIndex: currentProjectile.column, with: "o")
        a[a.startIndex.advanced(by: currentProjectile.row)] = r
    }
    if let currentProjectile = projectilePosition, projectilePosition == lastBlown {
        r = a[a.startIndex.advanced(by: currentProjectile.row)]
        r.replace(atIndex: currentProjectile.column, with: "\(ANSIColors.red.rawValue)O\(ANSIColors.reset.rawValue)")
        //r.replace(atIndex: currentProjectile.column, with: "o")
        a[a.startIndex.advanced(by: currentProjectile.row)] = r
    }
    print(a.joined(separator: "\n"))
}

func printField(asteroids: [[Bool]], station: Point, lastBlown: Point? = nil) {
    if let lastBlown = lastBlown {
        var curCol = station.column
        var curRow = station.row
        //print("\(station) -> \(lastBlown)")
        var positions = [Point]()
        var characters = [Character?]()
        while curRow != lastBlown.row && curCol != lastBlown.column {
            var projectile: Character? = nil
            let cols = max(curCol, lastBlown.column) - min(curCol, lastBlown.column)
            let rows = max(curRow, lastBlown.row) - min(curRow, lastBlown.row)
            let ratio = abs(Double(rows) / Double(cols))
            /*
             * TODO:
             * Add \ and /
             * Make laser 3 chars long
             * Find fitting horizontal unicode characters
             */
            if ratio >= 0.5 {
                curRow += station.row > lastBlown.row ? -1 : 1
                if ratio > 4 {
                    projectile = "|"
                }
            }
            if ratio <= 3.5 {
                if ratio < 0.4 {
                    projectile = "-"
                }
                curCol += station.column > lastBlown.column ? -1 : 1
            }
            positions.append(Point(row: curRow, column: curCol))
            characters.append(projectile)
            /*
            print("----")
            printField(asteroids: asteroids, station: station, lastBlown: lastBlown, projectilePosition: Point(row: curRow, column: curCol), projectile: projectile)
            usleep(50000)
             */
        }
        var idx = positions.startIndex
        while idx < positions.endIndex {
            print("----")
            let end = min(idx.advanced(by: 2), positions.index(before: positions.endIndex))
            let pos = positions[idx...end]
            printField(asteroids: asteroids, station: station, lastBlown: lastBlown, projectilePositions: pos, projectiles: characters[idx...end])
            idx = idx.advanced(by: 1)
            usleep(50000)
        }
        
    }
    printField(asteroids: asteroids, station: station, lastBlown: nil, projectilePosition: nil, projectile: nil)
    //print(FileManager.default.currentDirectoryPath)
}


func go(input: String) {
    let lines = input.split(separator: "\n")
    var asteroids = [[Bool]]()
    
    for line in lines {
        asteroids.append(line.map {$0 == "#" })
    }
    var counts = [Point:Int]()
    var blockedAngles = [Double: (Int, Int)]()
    var maxVisible = 0
    var station = Point(row: 0, column: 0)
    for (currentRow, row) in asteroids.enumerated() {
        for (currentColumn, location) in row.enumerated() {
            if !location {
                continue
            }
            let visible = getVisible(asteroids: asteroids, currentRow: currentRow, currentColumn: currentColumn, width: row.count)
            let currentCoord = Point(row: currentRow, column: currentColumn)
            counts[currentCoord] = visible.count
            if visible.count > maxVisible {
                blockedAngles = visible
                maxVisible = visible.count
                station = currentCoord
            }
        }
    }
    var part2: Int? = nil
    var total = 0
    while blockedAngles.count > 0 {
        let order = blockedAngles.sorted { $0.key < $1.key }
        for (ctr, nextOffset) in order.enumerated() {
            let target = Point(row: nextOffset.value.0 + station.row, column: nextOffset.value.1 + station.column)
            asteroids[target.row][target.column] = false
            if ctr == 199 && part2 == nil {
                part2 = target.column*100+target.row
            }
            printField(asteroids: asteroids, station: station, lastBlown: target)
        }
        total = order.count
        blockedAngles = getVisible(asteroids: asteroids, currentRow: station.row, currentColumn: station.column, width: asteroids[0].count)
    }
    
    print("\(maxVisible) for asteroid \(station)")
    print(part2!)
    print(blockedAngles)
    print(total)
    
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

let input = """
.#..#..###
####.###.#
....###.#.
..###.##.#
##.##.#.#.
....###..#
..#.#..#.#
#..#.#.###
.##...##.#
.....#.#..
"""
//go(input: input)

go(input: fileContents)
