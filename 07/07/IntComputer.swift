import Foundation

public typealias Adress = Int
public typealias Memory = [Int]
public typealias Value = Int
public typealias Output = (Value) -> Void
public typealias Input = () -> Value?

public enum ProgramState {
    case initialized
    case waitingForInput
    case running
    case finished
}

public class IOProgram {
    private var programCounter: Int
    private var memory: Memory
    private var input: Input = {() -> Value? in nil }
    private var output: Output
    private var inputQueue: Queue<Value>?
    public private(set) var state: ProgramState
    
    private init(program: Memory, output: @escaping Output) {
        self.memory = program
        self.programCounter = 0
        self.output = output
        self.state = .initialized
    }
    
    convenience init(program: Memory, input: @escaping Input, output: @escaping Output) {
        self.init(program: program, output: output)
        self.input = input
    }
    
    convenience init(program: Memory, inputQueue: Queue<Value>, output: @escaping Output) {
        self.init(program: program, output: output)
        self.input = dequeueInput
        self.inputQueue = inputQueue
    }
    
    public static func parse(program: String) -> Memory {
        return program.split(separator: ",").map {Int($0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!}
    }
    
    public func queueInput(_ value: Value) {
        self.inputQueue?.enqueue(value)
    }
    
    private func dequeueInput() -> Value? {
        return inputQueue?.dequeue()
    }
    
    private func step() {
        let opCode = memory[programCounter]
        let operation = Operation(opCode: opCode)
        var instruction: Instruction
        
        let parameters = Parameters(opCode: opCode)
        switch operation {
        case .add:
            instruction = ArithemticInstruction(operation: +)
        case .mul:
            instruction = ArithemticInstruction(operation: *)
        case .inp:
            instruction = InputInstruction(value: input())
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
        }
        
        programCounter = instruction.exec(
          memory: &memory,
          programCounter: programCounter,
          parameters: parameters
        )
        if let newState = instruction.stateOverwrite {
            state = newState
        }
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
    var stateOverwrite: ProgramState? { get }
    mutating func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress
}

struct ArithemticInstruction: Instruction {
    let operation: (Value, Value) -> Value
    let stateOverwrite: ProgramState? = nil
    
    mutating func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
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
    var value: Value?
    var stateOverwrite: ProgramState? = nil
    
    mutating func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        guard let value = value else {
            stateOverwrite = .waitingForInput
            return programCounter
        }
        let inputAdress = memory[programCounter + 1]
        
        // Always positional
        memory[inputAdress] = value
        return programCounter + 2
    }
}

struct OutputInstruction: Instruction {
    let output: Output
    let stateOverwrite: ProgramState? = nil
    
    mutating func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let valueAdress = memory[programCounter + 1]
        
        output(parameters.first.fetchValue(memory: memory, pointer: valueAdress))
        return programCounter + 2
    }
}

struct JumpInstruction: Instruction {
    let condition: (Value) -> Bool
    let stateOverwrite: ProgramState? = nil
    
    mutating func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let valueAdress = memory[programCounter + 1]
        let destinationAdress = memory[programCounter + 2]
        
        let value = parameters.first.fetchValue(memory: memory, pointer: valueAdress)
        let destination = parameters.second.fetchValue(memory: memory, pointer: destinationAdress)
        
        return condition(value) ? destination : programCounter + 3
    }
}

struct CompareInstruction: Instruction {
    let compare: (Value, Value) -> Bool
    let stateOverwrite: ProgramState? = nil
    
    mutating func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
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
    let stateOverwrite: ProgramState? = .finished
    
    mutating func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        return programCounter
    }
}
