import Foundation

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
        outputs[ampIndex] = output
        if let index = nextAmp {
            amps[index].queueInput(output)
        }
    }
    
    func saveAmpOutput(ampIndex: Int, output: Value, loopFedback: Bool) {
        let nextAmp: Int? = inputQueues.count > ampIndex+1 ? ampIndex+1 : loopFedback ? 0 : nil
        saveAmpOutput(ampIndex: ampIndex, output: output, connectToInput: nextAmp)
    }
    
    func getAmpInput(amp: Int) -> Value? {
        let val = inputQueues[amp].dequeue()
        return val
    }
    
    for (index, phase) in sequence.enumerated() {
        let prog = IOProgram(program: memory, inputQueue: Queue<Value>(initialValue: phase), output: { saveAmpOutput(ampIndex: index, output: $0, loopFedback: loopFedback) })
        if index == 0 {
            prog.queueInput(0)
        }
        amps.append(prog)
    }
    
    for amp in amps {
        amp.run()
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

func go(input: String, loopFeedback: Bool = false) {
    let sequences = Set(getPermutations(of: loopFeedback ? 56789 : 43210).map { getDigits($0, fillToNumberOfDigits: 5) })
    let memory = IOProgram.parse(program: input)
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
