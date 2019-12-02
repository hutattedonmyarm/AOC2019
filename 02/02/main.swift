import Foundation

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

var input = fileContents.split(separator: ",").map {Int($0.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))!}

input[1] = 12
input[2] = 2

var index = 0
var opCode = input[index]
repeat {
    let value1 = input[input[index+1]]
    let value2 = input[input[index+2]]
    var result = 0
    if opCode == 1 {
        result = value1 + value2
    } else if opCode == 2 {
        result = value1 * value2
    }
    input[input[index+3]] = result
    index += 4
    opCode = input[index]
} while opCode != 99

print(input[0])
