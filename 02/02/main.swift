import Foundation

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

var originalInput = fileContents.split(separator: ",").map {Int($0.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))!}

let desiredOutput = 19690720
var doBreak = false

var input = originalInput
for noun in 0...99 {
    for verb in 0...99 {
        input = originalInput
        input[1] = noun
        input[2] = verb

        var index = 0
        var opCode = input[index]
        
        repeat {
            let adress1 = input[index+1]
            let adress2 = input[index+2]
            
            
            let tooLarge = max(adress1, adress2) - input.count
            if (tooLarge > 0) {
                input.append(contentsOf: Array(repeating: 0, count: tooLarge))
            }
            
            let value1 = input[adress1]
            let value2 = input[adress2]
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
        if input[0] == desiredOutput {
            print(noun)
            print(verb)
            print(100*noun + verb)
            break
        }
    }
    if input[0] == desiredOutput {
        break
    }
}

print(input[0])
