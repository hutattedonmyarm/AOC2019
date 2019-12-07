import Foundation

typealias Adress = Int
typealias Memory = [Int]
typealias Value = Int
typealias Output = (Value) -> Void
typealias Input = () -> Value?

enum ProgramState {
    case initialized
    case waitingForInput
    case running
    case finished
}

class IOProgram {
    private var programCounter: Int
    private var memory: Memory
    private var input: Input
    private var output: Output
    public private(set) var state: ProgramState
    
    init(program: Memory, input: @escaping Input, output: @escaping Output) {
        self.memory = program
        self.programCounter = 0
        self.input = input
        self.output = output
        self.state = .initialized
    }
    
    private func step() {
        let opCode = memory[programCounter]
        let operation = Operation(opCode: opCode)
        let instruction: Instruction
        
        let parameters = Parameters(opCode: opCode)
        switch operation {
        case .add:
            instruction = ArithemticInstruction(operation: +)
        case .mul:
            instruction = ArithemticInstruction(operation: *)
        case .inp:
            guard let inp = input() else {
                state = .waitingForInput
                return
            }
            instruction = InputInstruction(value: inp)
        case .out:
            instruction = OutputInstruction(output: output)
        case .jtr:
            instruction = JumpInstruction() { $0 != 0 }
        case .jfa:
            instruction = JumpInstruction() { $0 == 0 }
        case .lt:
            instruction = CompareInstruction() { $0 < $1 }
        case .eq:
            instruction = CompareInstruction() { $0 == $1 }
        case .hlt:
            instruction = HaltInstruction()
            state = .finished
        }
        
        programCounter = instruction.exec(
          memory: &memory,
          programCounter: programCounter,
          parameters: parameters
        )
    }
    
    public func run() {
        switch state {
        case .finished, .running:
            return
        default:
            state = .running
        }
        while state == .running {
            step()
        }
    }
}

func getDigits(_ number: Int, fillToNumberOfDigits numberOfDigits: Int? = nil) -> [Int] {
    var digits = [Int]()
    var num = number
    while num > 0 {
        digits.append(num % 10)
        num /= 10
    }
    if let numDigits = numberOfDigits {
        while digits.count < numDigits {
            digits.insert(0, at: 0)
        }
    }
    return digits
}

// https://codereview.stackexchange.com/questions/209791/swift-permutations-of-the-digits-of-an-integer
func getPermutations(of number: Int) -> [Int] {
    var perms = [Int]()
    
    func permutations(of digits: [Int], withSuffix suffix: [Int]) {
        if digits.isEmpty {
            perms.append(Int(suffix.reduce(0, { $0 * 10 + Int($1) })))
        } else {
            for i in digits.indices {
                var remainingDigits = digits
                let currentDigit = [remainingDigits.remove(at: i)]
                permutations(of: remainingDigits, withSuffix: currentDigit + suffix)
            }
        }
    }

    permutations(of: getDigits(number), withSuffix: [])
    return perms
}

func runSequence(memory: Memory, sequence: [Value], loopFedback: Bool = false) -> Value {
    let numAmps = sequence.count
    var inputQueues = sequence.map { Queue<Value>(initialValue: $0) }
    inputQueues[0].enqueue(0)
    
    var amps = [IOProgram]()
    var outputs: [Value] = [0, 0, 0, 0, 0]
    
    func saveAmpOutput(ampIndex: Int, output: Value, connectToInput nextAmp: Int?) {
        //print("Amp \(ampIndex) => \(output)")
        outputs[ampIndex] = output
        if let index = nextAmp {
            inputQueues[index].enqueue(output)
        }
    }
    
    func saveAmpOutput(ampIndex: Int, output: Value, loopFedback: Bool) {
        let nextAmp: Int? = inputQueues.count > ampIndex+1 ? ampIndex+1 : loopFedback ? 0 : nil
        saveAmpOutput(ampIndex: ampIndex, output: output, connectToInput: nextAmp)
    }
    
    func getAmpInput(amp: Int) -> Value? {
        let val = inputQueues[amp].dequeue()
        //print("\(val) => Amp \(amp)")
        return val
    }
    
    for amp in 0..<numAmps {
        let prog = IOProgram(program: memory, input: { getAmpInput(amp: amp) }, output: { saveAmpOutput(ampIndex: amp, output: $0, loopFedback: loopFedback) })
        prog.run()
        amps.append(prog)
    }
    var allDone = true
    repeat {
        allDone = true
        for amp in amps {
            amp.run()
            allDone = allDone && amp.state == .finished
        }
    } while !allDone
    return outputs.last!
}

enum Operation: Int {
    case add = 1
    case mul = 2
    case inp = 3
    case out = 4
    case jtr = 5
    case jfa = 6
    case lt = 7
    case eq = 8
    case hlt = 99
    
    init(opCode: Int) {
        self.init(rawValue: opCode % 100)!
    }
    
    var description : String {
        switch self {
        case .add: return "add"
        case .mul: return "mul"
        case .inp: return "inp"
        case .out: return "out"
        case .jtr: return "jtr"
        case .jfa: return "jfa"
        case .lt: return "let"
        case .eq: return "equ"
        case .hlt: return "hlt"
        }
    }
}

enum Mode: Int {
    case position = 0
    case immediate = 1

    func fetchValue(memory: Memory, pointer: Adress) -> Value {
        switch self {
        case .position:
            return memory[pointer]
        case .immediate:
            return pointer
        }
    }
}

struct Parameters {
    let first: Mode
    let second: Mode
    let third: Mode

    init(opCode: Int) {
        self.first = Mode(rawValue: opCode / 100 % 10)!
        self.second = Mode(rawValue: opCode / 1000 % 10)!
        self.third = Mode(rawValue: opCode / 10000 % 10)!
    }
}

protocol Instruction {
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress
}

struct ArithemticInstruction: Instruction {
    let operation: (Value, Value) -> Value
    
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let firstAddendAdress = memory[programCounter + 1]
        let secondAddendAdress = memory[programCounter + 2]
        let resultAdress = memory[programCounter + 3]
        
        let first = parameters.first.fetchValue(memory: memory, pointer: firstAddendAdress)
        let second = parameters.second.fetchValue(memory: memory, pointer: secondAddendAdress)

        memory[resultAdress] = operation(first, second)
        return programCounter + 4
    }
}

struct InputInstruction: Instruction {
    let value: Value
    
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let inputAdress = memory[programCounter + 1]
        
        // Always positional
        memory[inputAdress] = value
        return programCounter + 2
    }
}

struct OutputInstruction: Instruction {
    let output: Output
    
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let valueAdress = memory[programCounter + 1]
        
        output(parameters.first.fetchValue(memory: memory, pointer: valueAdress))
        return programCounter + 2
    }
}

struct JumpInstruction: Instruction {
    let condition: (Value) -> Bool
    
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let valueAdress = memory[programCounter + 1]
        let destinationAdress = memory[programCounter + 2]
        
        let value = parameters.first.fetchValue(memory: memory, pointer: valueAdress)
        let destination = parameters.second.fetchValue(memory: memory, pointer: destinationAdress)
        
        return condition(value) ? destination : programCounter + 3
    }
}

struct CompareInstruction: Instruction {
    let compare: (Value, Value) -> Bool
    
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let firstValueAdress = memory[programCounter + 1]
        let secondValueAdress = memory[programCounter + 2]
        let resultAdress = memory[programCounter + 3]
        
        let firstValue = parameters.first.fetchValue(memory: memory, pointer: firstValueAdress)
        let secondValue = parameters.second.fetchValue(memory: memory, pointer: secondValueAdress)
        let result = compare(firstValue, secondValue) ? 1 : 0
        
        memory[resultAdress] = result
        return programCounter + 4
    }
}

struct HaltInstruction: Instruction {
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        return programCounter
    }
}

func parse(program: String) -> Memory {
    return program.split(separator: ",").map {Int($0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!}
}

func go(input: String, loopFeedback: Bool = false) {
    let sequences = Set(getPermutations(of: loopFeedback ? 56789 : 43210).map { getDigits($0, fillToNumberOfDigits: 5) })
    let memory = parse(program: input)
    var maxResult: Value = Int.min
    var signal = [Int]()
    for sequence in sequences {
        //print("Checking \(sequence)")
        let result = runSequence(memory: memory, sequence: sequence, loopFedback: loopFeedback)
        if result > maxResult {
            maxResult = result
            signal = sequence
        }
        //print("Got \(result)")
    }
    print("\(signal) => \(maxResult)")
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

//go(input: "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0")
//go(input: "3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0")
//go(input: "3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0")

go(input: fileContents)
//go(input: "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5", loopFeedback: true)
//go(input: "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10", loopFeedback: true)
go(input: fileContents, loopFeedback: true)
