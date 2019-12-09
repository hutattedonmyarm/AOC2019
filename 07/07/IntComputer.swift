import Foundation

public typealias Adress = Int
public typealias Value = Int
public typealias Memory = [Value]
public typealias Output = (Value) -> Void
public typealias Input = () -> Value?

var debug = false

public struct RAM {
    private var memory: Memory
    public var size: Int {
        return memory.count
    }
    
    public init(withMemory memory: Memory) {
        self.memory = memory
    }
    
    mutating private func ensureAdress(_ adress: Adress) {
        while adress >= memory.count {
            let newMem = Memory(repeating: 0, count: memory.count)
            memory.append(contentsOf: newMem)
        }
    }
    
    mutating public func write(value: Value, at adress: Adress) {
        ensureAdress(adress)
        memory[adress] = value
    }
    
    mutating public func read(at adress: Adress) -> Value {
        ensureAdress(adress)
        return memory[adress]
    }
    
    subscript(index: Int) -> Value {
        mutating get {
            return read(at: index)
        }
        set(newValue) {
            write(value: newValue, at: index)
        }
    }
    
}

public enum ProgramState {
    case initialized
    case waitingForInput
    case running
    case finished
}

public class IOProgram {
    private var programCounter: Int
    private var memory: RAM
    private var input: Input = {() -> Value? in nil }
    private var output: Output
    private var inputQueue: Queue<Value>?
    private var relativeBase: Adress
    public private(set) var state: ProgramState
    private var assemblyCode: [String]
    
    private init(program: Memory, output: @escaping Output) {
        self.memory = RAM(withMemory: program)
        self.programCounter = 0
        self.output = output
        self.state = .initialized
        self.relativeBase = 0
        self.assemblyCode = [String]()
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
    
    public func enableDebug() {
        debug = true
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
    
    private func step(decompile: Bool = false) {
        if decompile && programCounter == memory.size {
            state = .finished
            return
        }
        let opCode = memory[programCounter]
        guard let operation = Operation(opCode: opCode) else {
            if decompile {
                assemblyCode.insert("add $0 $0 \(programCounter)", at: 0)
            } else {
                // Should never happen in valid IntCode
                fatalError("Invalid OopCode \(opCode) at index \(programCounter)")
            }
            programCounter += 1
            return
        }
        var instruction: Instruction
        
        let parameters = Parameters(opCode: opCode, relativeBase: self.relativeBase)
        if debug {
            print("\(operation) (\(opCode)) at \(programCounter)")
        }
        var codeLine = "\(operation) "
        switch operation {
        case .add:
            instruction = ArithemticInstruction(operation: +)
        case .mul:
            instruction = ArithemticInstruction(operation: *)
        case .inp:
            let v = input()
            instruction = InputInstruction(value: v, stateOverwrite: nil)
        case .out:
            instruction = OutputInstruction(output: output)
        case .jnz:
            instruction = JumpInstruction() { $0 != 0 }
        case .jz:
            instruction = JumpInstruction() { $0 == 0 }
        case .lt:
            instruction = CompareInstruction() { $0 < $1 }
        case .eq:
            instruction = CompareInstruction() { $0 == $1 }
        case .rlb:
            instruction = AdjustRelativeBaseInstruction() {
                self.relativeBase += $0
            }
        case .hlt:
            instruction = HaltInstruction()
        }
        
        if !decompile {
            programCounter = instruction.exec(
                memory: &memory,
                programCounter: programCounter,
                parameters: parameters
            )
            if let newState = instruction.stateOverwrite {
                state = newState
            }
        } else {
            codeLine += instruction.getParameterAssembly(
                memory: &memory,
                programCounter: programCounter,
                parameters: parameters
            )
            self.assemblyCode.append(codeLine)
            programCounter += instruction.instructionSize
        }
    }
    
    public func run() {
        if debug {
            print("Go")
        }
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
    
    public func decompile() -> String {
        assemblyCode = [String]()
        while state != .finished {
            step(decompile: true)
        }
        return assemblyCode.joined(separator: "\n")
    }
}

enum Operation: Int {
    case add = 1
    case mul = 2
    case inp = 3
    case out = 4
    case jnz = 5
    case jz = 6
    case lt = 7
    case eq = 8
    case rlb = 9
    case hlt = 99
    
    init?(opCode: Int) {
        self.init(rawValue: opCode % 100)
    }
    
    var description : String {
        switch self {
        case .add: return "add"
        case .mul: return "mul"
        case .inp: return "inp"
        case .out: return "out"
        case .jnz: return "jtr"
        case .jz: return "jfa"
        case .lt: return "let"
        case .eq: return "equ"
        case .hlt: return "hlt"
        case .rlb: return "rlb"
        }
    }
}

enum Mode: Int {
    case position = 0
    case immediate = 1
    case relative = 2
    
    func fetchValue(memory mem: RAM, pointer: Adress, relativeBase: Adress) -> Value {
        var memory = mem
        switch self {
        case .position:
            return memory[pointer]
        case .immediate:
            return pointer
        case .relative:
            let val = memory[pointer+relativeBase]
            if debug {
                print("relative Base: \(relativeBase). pointer: \(pointer). Final adress: \(pointer+relativeBase). Value: \(val)")
            }
            return val
        }
    }
    
    func fetchAdress(pointer: Adress, relativeBase: Adress) -> Adress? {
        switch self {
        case .position:
            return pointer
        case .immediate:
            return nil
        case .relative:
            let val = pointer+relativeBase
            if debug {
                print("relative Base: \(relativeBase). pointer: \(pointer). Final adress: \(val)")
            }
            return val
        }
    }
    
    func getPrefix() -> String {
        switch self {
        case .position:
            return ""
        case .immediate:
            return "$"
        case .relative:
            return "%"
        }
    }
}

struct Parameters {
    let first: Mode
    let second: Mode
    let third: Mode
    let relativeBase: Adress
    
    init(opCode: Int, relativeBase: Adress) {
        self.first = Mode(rawValue: opCode / 100 % 10)!
        self.second = Mode(rawValue: opCode / 1000 % 10)!
        self.third = Mode(rawValue: opCode / 10000 % 10)!
        self.relativeBase = relativeBase
    }
}

protocol Instruction {
    var stateOverwrite: ProgramState? { get }
    var instructionSize: Adress { get }
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress
}

struct ArithemticInstruction: Instruction {
    let instructionSize = 4
    let operation: (Value, Value) -> Value
    let stateOverwrite: ProgramState? = nil
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String {
        var str = "\(parameters.first.getPrefix())\(memory[programCounter + 1]), "
        str += "\(parameters.second.getPrefix())\(memory[programCounter + 2]), "
        str += "\(parameters.third.getPrefix())\(memory[programCounter + 3])"
        return str
    }
    
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress {
        let firstAddendAdress = memory[programCounter + 1]
        let secondAddendAdress = memory[programCounter + 2]
        let resultParam = memory[programCounter + 3]
        
        let first = parameters.first.fetchValue(memory: memory, pointer: firstAddendAdress, relativeBase: parameters.relativeBase)
        let second = parameters.second.fetchValue(memory: memory, pointer: secondAddendAdress, relativeBase: parameters.relativeBase)
        let resultAdress = parameters.third.fetchAdress(pointer: resultParam, relativeBase: parameters.relativeBase)!
        
        memory[resultAdress] = operation(first, second)
        
        if debug {
            let res = operation(first, second)
            print("Arithemtic: \(first), \(second) => \(res)")
        }
        
        return programCounter + instructionSize
    }
}

struct InputInstruction: Instruction {
    var value: Value?
    var stateOverwrite: ProgramState? = nil
    let instructionSize = 2
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String {
        return "\(parameters.first.getPrefix())\(memory[programCounter + 1])"
    }
    
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress {
        guard let value = value else {
            stateOverwrite = .waitingForInput
            return programCounter
        }
        let inputParam = memory[programCounter + 1]
        let inputAdress = parameters.first.fetchAdress(pointer: inputParam, relativeBase: parameters.relativeBase)!
        memory[inputAdress] = value
        if debug {
            print("Input: \(value) written to: \(inputAdress)")
        }
        return programCounter + instructionSize
    }
}

struct OutputInstruction: Instruction {
    let output: Output
    let stateOverwrite: ProgramState? = nil
    let instructionSize = 2
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String {
        return "\(parameters.first.getPrefix())\(memory[programCounter + 1])"
    }
    
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress {
        let valueAdress = memory[programCounter + 1]
        
        output(parameters.first.fetchValue(memory: memory, pointer: valueAdress, relativeBase: parameters.relativeBase))
        
        return programCounter + instructionSize
    }
}

struct JumpInstruction: Instruction {
    let condition: (Value) -> Bool
    let stateOverwrite: ProgramState? = nil
    let instructionSize = 3
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String {
        var str = "\(parameters.first.getPrefix())\(memory[programCounter + 1]), "
        str += "\(parameters.second.getPrefix())\(memory[programCounter + 2])"
        return str
    }
    
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress {
        let valueAdress = memory[programCounter + 1]
        let destinationAdress = memory[programCounter + 2]
        
        let value = parameters.first.fetchValue(memory: memory, pointer: valueAdress, relativeBase: parameters.relativeBase)
        let destination = parameters.second.fetchValue(memory: memory, pointer: destinationAdress, relativeBase: parameters.relativeBase)
        
        if debug {
            let res = condition(value)
            print("\(res ? "" : "not") jumping to: \(destination)")
        }
        
        return condition(value) ? destination : programCounter + instructionSize
    }
}

struct CompareInstruction: Instruction {
    let compare: (Value, Value) -> Bool
    let stateOverwrite: ProgramState? = nil
    let instructionSize = 4
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String {
        var str = "\(parameters.first.getPrefix())\(memory[programCounter + 1]), "
        str += "\(parameters.second.getPrefix())\(memory[programCounter + 2]), "
        str += "\(parameters.third.getPrefix())\(memory[programCounter + 3])"
        return str
    }
    
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress {
        let firstValueAdress = memory[programCounter + 1]
        let secondValueAdress = memory[programCounter + 2]
        let resultParameter = memory[programCounter + 3]
        
        let firstValue = parameters.first.fetchValue(memory: memory, pointer: firstValueAdress, relativeBase: parameters.relativeBase)
        let secondValue = parameters.second.fetchValue(memory: memory, pointer: secondValueAdress, relativeBase: parameters.relativeBase)
        let resultAdress = parameters.third.fetchAdress(pointer: resultParameter, relativeBase: parameters.relativeBase)!
        
        let result = compare(firstValue, secondValue) ? 1 : 0
        
        memory[resultAdress] = result
        
        if debug {
            print("Compare: \(firstValue), \(secondValue) => \(result)")
        }
        
        return programCounter + instructionSize
    }
}

struct HaltInstruction: Instruction {
    let stateOverwrite: ProgramState? = .finished
    let instructionSize = 1
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String {
        return ""
    }
    
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress {
        if debug {
            print(memory)
        }
        return programCounter + instructionSize
    }
}

struct AdjustRelativeBaseInstruction: Instruction {
    let stateOverwrite: ProgramState? = nil
    let updateRelativeBase: (Int) -> Void
    let instructionSize = 2
    
    func getParameterAssembly(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> String {
        return "\(parameters.first.getPrefix())\(memory[programCounter + 1])"
        
    }
    
    mutating func exec(memory: inout RAM, programCounter: Adress, parameters: Parameters) -> Adress {
        let firstValueAdress = memory[programCounter + 1]
        
        let firstValue = parameters.first.fetchValue(memory: memory, pointer: firstValueAdress, relativeBase: parameters.relativeBase)
        updateRelativeBase(firstValue)
        return programCounter + instructionSize
    }
}
