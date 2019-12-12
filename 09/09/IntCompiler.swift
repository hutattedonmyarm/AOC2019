import Foundation

func compile(code: [String]) {
    for instruction in code {
        let x = instruction.split(separator: " ")
        let op = Operation.init(instruction: x.description)
    }
}
