import Foundation

func checkNumber(_ num: Int, partTwo: Bool = false) -> Bool {
    let str = String(num)
    var numStreak = 1
    var streaks = [Int]()
    var hasDouble = false
    var doesNotDecrease = true
    var idx = str.startIndex
    var last = str[idx]
    while idx < str.index(before: str.endIndex) {
        idx = str.index(after: idx)
        let current = str[idx]
        if current == last {
            numStreak += 1
            hasDouble = true
        } else {
            streaks.append(numStreak)
            numStreak = 1
        }
        
        if current < last {
            doesNotDecrease = false
            break
        }
        last = current
    }
    streaks.append(numStreak)
    return (partTwo && streaks.filter {$0 == 2}.count > 0 || !partTwo && hasDouble) && doesNotDecrease
}

let lower = 168630
let upper = 718098

let range = lower...upper

print(range.filter{checkNumber($0)}.count)
print(range.filter{checkNumber($0, partTwo: true)}.count)
