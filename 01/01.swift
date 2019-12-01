import Foundation

func getFuel(forMass mass: Int) -> Int {
  var fuel = 0
  var newFuel = mass
  while newFuel > 0 {
    newFuel = newFuel / 3 - 2
    fuel += newFuel
  }
  fuel -= newFuel
  return fuel
}

func getValues() -> [Int] {
  let path = "./input.txt"
  guard let text = try? String(contentsOfFile: path as String, encoding: .utf8) else {
    return []
  }
  return text.split(separator: "\n").map { getFuel(forMass: Int($0)!)}
}

print(getValues().reduce(0, +))
