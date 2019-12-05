import Foundation

func checkNumber(_ num: Int) -> (Bool, Bool) {
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
    return (hasDouble && doesNotDecrease, doesNotDecrease && streaks.filter {$0 == 2}.count > 0)
}

let lower = 168630
let upper = 718098
let range = lower...upper

var t = (0, 0)
for num in range {
    let check = checkNumber(num)
    t.0 += check.0 ? 1 : 0
    t.1 += check.1 ? 1 : 0
}

print(t)
