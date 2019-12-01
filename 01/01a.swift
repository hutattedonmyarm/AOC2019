import Foundation

func getFuel(forMass mass: Int) -> Int {
  return mass / 3 - 2
}

func getValues() -> [Int] {
  let path = "./input.txt"
  guard let text = try? String(contentsOfFile: path as String, encoding: .utf8) else {
    return []
  }
  return text.split(separator: "\n").map { getFuel(forMass: Int($0)!)}
}

print(getValues().reduce(0, +))
