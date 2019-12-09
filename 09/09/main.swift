import Foundation

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

let mem = IOProgram.parse(program: fileContents)
let output: Output = {
    print("Output: ", terminator: "")
    print($0)
}
let prg = IOProgram(program: mem, inputQueue: Queue<Value>(initialValue: 1), output: output)
prg.run()

let part2 = IOProgram(program: mem, inputQueue: Queue<Value>(initialValue: 2), output: output)
part2.queueInput(2)
part2.run()

let decompiler = IOProgram(program: mem, inputQueue: Queue<Value>(initialValue: 2), output: output)
let assemblyCode = decompiler.decompile()
print(assemblyCode)
