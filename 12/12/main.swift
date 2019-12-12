import Foundation

typealias Vector = [Int]

enum Axis: Int {
  case x = 0
  case y
  case z
}

func simulate(positions: inout Vector, velocities: inout Vector) {
  for i in positions.startIndex..<positions.index(before: positions.endIndex) {
    for j in positions.startIndex.advanced(by: i)..<positions.endIndex {
      if positions[i] == positions[j] {
        continue
      } else if positions[i] < positions[j] {
        velocities[i] += 1
        velocities[j] -= 1
      } else {
        velocities[i] -= 1
        velocities[j] += 1
      }
    }
  }

  for i in positions.startIndex..<positions.endIndex {
    positions[i] += velocities[i]
  }
}

func go(input: String) {
    let lines = input.split(separator: "\n")
    let coords = "<x=(-?\\d+), y=(-?\\d+), z=(-?\\d+)>"
    let coordsPattern = try! NSRegularExpression(pattern: coords, options: [])
    
    var positions = [Vector(), Vector(), Vector()]
    var velocities = [Vector(), Vector(), Vector()]
        
    for line in lines {
        let l = line.description
        let m = coordsPattern.matches(in: l, options: [], range: NSRange(l.startIndex..., in: l)).first!
        let rx = Range(m.range(at: 1), in: l)!
        let ry = Range(m.range(at: 2), in: l)!
        let rz = Range(m.range(at: 3), in: l)!
        let x = Int(l[rx])!
        let y = Int(l[ry])!
        let z = Int(l[rz])!

        positions[0].append(x)
        positions[1].append(y)
        positions[2].append(z)
        velocities[0].append(0)
        velocities[1].append(0)
        velocities[2].append(0)
    }


    let givenPositions = positions
    let givenVelocities = velocities
    
    var step = 0
    while step < 1000 {
        for index in positions.startIndex..<positions.endIndex {
          simulate(positions: &positions[index], velocities: &velocities[index])
        }
        step += 1
    }
    var totalEnergy = 0
    
    for i in positions.first!.startIndex..<positions.first!.endIndex {
      var potential = 0
      var kinetic = 0
      for j in positions.startIndex..<positions.endIndex {
        potential += abs(positions[j][i])
        kinetic += abs(velocities[j][i])
      }
      totalEnergy += potential*kinetic
    }
   
    print(totalEnergy)

    positions = givenPositions
    velocities = givenVelocities

    var steps = [Int](repeating: 0, count: positions.count)

    for i in positions.startIndex..<positions.endIndex {
      step = 0
      while steps[i] == 0 {
        simulate(positions: &positions[i], velocities: &velocities[i])
        step += 1
        if givenPositions[i] == positions[i] && givenVelocities[i] == velocities[i] {
          steps[i] = step
        }
      }
    }

    var totalSteps = steps.first!
    for i in steps.index(after: steps.startIndex)..<steps.endIndex {
      totalSteps = lcm(totalSteps, steps[i])
    }

    print(totalSteps)
}

func gcd(_ m: Int, _ n: Int) -> Int {
    var a: Int = 0
    var b: Int = max(m, n)
    var r: Int = min(m, n)
    
    while r != 0 {
        a = b
        b = r
        r = a % b
    }
    return b
}

func lcm(_ m: Int, _ n: Int) -> Int {
    return m / gcd(m, n) * n
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

go(input: fileContents)
