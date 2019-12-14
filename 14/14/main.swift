import Foundation

typealias Chemical = String
typealias Amount = Int

struct Ingredient: CustomStringConvertible {
    let chemical: Chemical
    var amount: Amount
    
    public var description: String {
        return "\(amount) \(chemical)"
    }
}

struct Reaction: CustomStringConvertible {
    let requires: [Ingredient]
    let produces: Ingredient
    
    public var description: String {
        return "\(requires.map { $0.description }.joined(separator: ", ")) => \(produces)"
    }
}

func go(input: String) {
    let lines = input.split(separator: "\n")
    var reactions = [Reaction]()
    let reactionPattern = "((?>\\d+ \\S+,? )+)=> (\\d+ \\S+)"
    let reactionRegex = try! NSRegularExpression(pattern: reactionPattern, options: [])
    
    for line in lines {
        let l = line.description
        let m = reactionRegex.matches(in: l, options: [], range: NSRange(l.startIndex..., in: l)).first!
        
        let result = l[Range(m.range(at: 2), in: l)!].split(separator: " ")
        let produces = Ingredient(chemical: result[1].description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), amount: Int(result[0])!)
        
        let needed = l[Range(m.range(at: 1), in: l)!].split(separator: ",")
        var requires = [Ingredient]()
        for n in needed {
            let req = n.split(separator: " ")
            let r = Ingredient(chemical: req[1].description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), amount: Int(req[0])!)
            requires.append(r)
        }
        reactions.append(Reaction(requires: requires, produces: produces))
    }
    let fuelNeeded = part1(reactions: reactions)
    print("\(fuelNeeded) Ore")
    part2(reactions: reactions)
    
}

func part1(reactions: [Reaction]) -> Amount {
    return calculateFuelRequirements(reactions: reactions).first { $0.chemical == "ORE" }!.amount
}

struct Cargo {
    // Todo: This looks an awful lot like a dictionary, paired with the
    // "ensure" stuff from the IntComputer RAM
    var ingredients: [Ingredient]
    init() {
        ingredients = [Ingredient]()
    }
    
    mutating public func store(ingredient: Ingredient) {
        if let idx = ingredients.firstIndex(where:{ ingredient.chemical == $0.chemical }) {
            ingredients[idx].amount += ingredient.amount
        } else {
            ingredients.append(ingredient)
        }
    }
    
    mutating public func retrieve(ingredient: Ingredient) {
        store(ingredient: Ingredient(chemical: ingredient.chemical, amount: -ingredient.amount))
    }
    
    mutating public func checkAmount(chemical: Chemical) -> Int {
        ingredients.first{ chemical == $0.chemical }?.amount ?? 0
    }
}

func part2(reactions: [Reaction]) {
    var cargo = Cargo()
    cargo.store(ingredient: Ingredient(chemical: "ORE", amount: 1000000000000))
    
    func produceIfPossible(ingredient: Ingredient) -> Bool {
        let reaction = reactions.first { $0.produces.chemical == ingredient.chemical }!
        let repeats = Int(ceil(Double(ingredient.amount) / Double(reaction.produces.amount)))
        if reaction.requires.filter({ $0.chemical == "ORE" && cargo.checkAmount(chemical: $0.chemical) < repeats * $0.amount }).count > 0 {
            return false
        }
        let old = cargo
        while let ingredient = reaction.requires.first(where: { cargo.checkAmount(chemical: $0.chemical) < repeats * $0.amount }) {
            let neededAmount = ingredient.amount * repeats - cargo.checkAmount(chemical: ingredient.chemical)
            if !produceIfPossible(ingredient: Ingredient(chemical: ingredient.chemical, amount: neededAmount)) {
                cargo = old
                return false;
            }
        }
        for required in reaction.requires {
            let amount = required.amount * repeats
            cargo.retrieve(ingredient: Ingredient(chemical: required.chemical, amount: amount))
        }
        
        let amount = reaction.produces.amount * repeats
        cargo.store(ingredient: Ingredient(chemical: ingredient.chemical, amount: amount))
        return true
    }
    
    var fuelToProduce = 100000000
    while fuelToProduce > 0 {
        var success: Bool
        repeat {
            success = produceIfPossible(ingredient: Ingredient(chemical: "FUEL", amount: fuelToProduce))
        } while success
        fuelToProduce /= 10
    }
    print(cargo.checkAmount(chemical: ("FUEL")))
}

func calculateFuelRequirements(reactions: [Reaction]) -> [Ingredient] {
    let fuelReaction = reactions.first { $0.produces.chemical == "FUEL" }!
    var needed = fuelReaction.requires
    let neededFilter: (Ingredient) -> Bool = { $0.chemical != "ORE" && $0.amount > 0}
    while let ingredient = needed.filter(neededFilter).first {
        let r = reactions.first { $0.produces.chemical == ingredient.chemical }!
        if let i = needed.firstIndex(where: { $0.chemical == r.produces.chemical}) {
            needed[i].amount -= r.produces.amount
            for required in r.requires {
                if let index = needed.firstIndex(where: { $0.chemical == required.chemical }) {
                    needed[index].amount += required.amount
                } else {
                    needed.append(required)
                }
            }
        }
    }
    return needed
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

go(input: fileContents)
