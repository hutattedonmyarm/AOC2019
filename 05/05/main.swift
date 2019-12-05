import Foundation

typealias Adress = Int
typealias Memory = [Int]
typealias Value = Int

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
    func exec(memory: inout Memory, programCounter: Adress, parameters: Parameters) -> Adress {
        let valueAdress = memory[programCounter + 1]
        
        print(parameters.first.fetchValue(memory: memory, pointer: valueAdress))
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

func run(input: Value, memory: Memory) {
    var mem = memory
    var programCounter = 0
    var finished = false
    
    while !finished {
        let opCode = mem[programCounter]
        let operation = Operation(opCode: opCode)
        let instruction: Instruction
        
        let parameters = Parameters(opCode: opCode)
        switch operation {
        case .add:
            instruction = ArithemticInstruction(operation: +)
        case .mul:
            instruction = ArithemticInstruction(operation: *)
        case .inp:
            instruction = InputInstruction(value: input)
        case .out:
            instruction = OutputInstruction()
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
            finished = true
        }
        
        programCounter = instruction.exec(
          memory: &mem,
          programCounter: programCounter,
          parameters: parameters
        )
    }
}

func run2(prgInput: Int, program: String) -> String {
    var input = program.split(separator: ",").map {Int($0.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))!}

    var index = 0
    var opCode = input[index]

    var prgOutput = ""

    repeat {
        let adress1 = input[index+1]
        let adress2 = input[index+2]
        let adress3 = input.count > index+3 ? input[index+3] : nil

        let mode1 = (opCode / 100) % 10
        let mode2 = (opCode / 1000) % 10
        let mode3 = (opCode / 10000) % 10
        
        opCode = opCode % 10
        
        var value1: Int? = nil
        var value2: Int? = nil
        var value3: Int? = nil
        var opCodeLength = 4
        var result = 0
        var resultAdress: Int? = adress3
        //print([index, opCode, adress1, adress2, adress3!, mode1, mode2], terminator: ": ")
        print(Operation(opCode: opCode))
        switch opCode {
        case 1:
            value1 = mode1 == 0 ? input[adress1] : adress1
            value2 = mode2 == 0 ? input[adress2] : adress2
            result = value1! + value2!
            print(value1!, value2!, resultAdress!)
            //print("\(result)=\(value1!)(\(adress1)) + \(value2!)(\(adress2)) => \(resultAdress!)")
        case 2:
            value1 = mode1 == 0 ? input[adress1] : adress1
            value2 = mode2 == 0 ? input[adress2] : adress2
            result = value1! * value2!
            //print("\(result)=\(value1!)(\(adress1)) * \(value2!)(\(adress2)) => \(resultAdress!)")
        case 3:
            result = prgInput
            resultAdress = adress1
            opCodeLength = 2
            //print("\(result) => \(resultAdress!)")
        case 4:
            value1 = mode1 == 0 ? input[adress1] : adress1
            opCodeLength = 2
            resultAdress = nil
            prgOutput += "\(value1!)"
            //print("Output: \(value1!) (\(adress1))")
        case 5:
            value1 = mode1 == 0 ? input[adress1] : adress1
            value2 = mode2 == 0 ? input[adress2] : adress2
            index = value1 != 0 ? value2! : index+3
            opCodeLength = 0
            resultAdress = nil
            //print("\(value1!)(\(adress1)) != 0 ? \(value1! != 0) => pc to \(index)")
        case 6:
            value1 = mode1 == 0 ? input[adress1] : adress1
            value2 = mode2 == 0 ? input[adress2] : adress2
            index = value1 == 0 ? value2! : index+3
            opCodeLength = 0
            resultAdress = nil
            //print("\(value1!)(\(adress1)) == 0 ? \(value1! == 0) => pc to \(index)")
        case 7:
            value1 = mode1 == 0 ? input[adress1] : adress1
            value2 = mode2 == 0 ? input[adress2] : adress2
            //value3 = mode3 == 0 ? input[adress3!] : adress3!
            result = value1! < value2! ? 1 : 0
            //resultAdress = value3
            resultAdress = adress3!
            //print("\(value1!)(\(adress1)) < \(value2!)(\(adress2)) ? \(result) => \(resultAdress!)")
        case 8:
            value1 = mode1 == 0 ? input[adress1] : adress1
            value2 = mode2 == 0 ? input[adress2] : adress2
            //value3 = mode3 == 0 ? input[adress3!] : adress3!
            result = value1! == value2! ? 1 : 0
            resultAdress = adress3!
            //print("\(value1!)(\(adress1)) == \(adress2)(\(adress2)) ? \(result) => \(resultAdress!)")
        default:
            break
        
        }
        if let ra = resultAdress {
            input[ra] = result
        }
        
        index += opCodeLength
        opCode = input[index]
    } while opCode != 99
    return prgOutput
}


guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

run(input: 5, memory: parse(program: fileContents))
