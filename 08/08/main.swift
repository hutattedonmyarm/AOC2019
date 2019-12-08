import Foundation
typealias Layer = [Pixel]

enum Pixel: Character, CustomStringConvertible {
    case black = "0"
    case white = "1"
    case transparent = "2"
    
    var description: String {
        switch self {
        case .transparent:
            return "."
        case .black:
            return " "
        case .white:
            return "*"
        }
    }
}

func getLayers(pixels: Layer, layerSize size: Int) -> [Layer] {
   return stride(from: 0, to: pixels.count, by: size).map {
       Array(pixels[$0..<($0 + size)])
   }
}

func validateImage(layers: [Layer]) -> Int {
    let countPixel = {(a: Layer, b: Pixel) -> Int in
        a.filter { $0 == b }.count
    }
    let min = layers.min { countPixel($0, .black) < countPixel($1, .black) }!
    let val = countPixel(min, .white) * countPixel(min, .transparent)
    
    return val
}

func decode(layers: [Layer]) -> Layer {
    var finalImage = layers.first!
    for layer in layers {
        for (idx, c) in layer.enumerated() {
            if finalImage[idx] == .transparent {
               finalImage[idx] = c
            }
        }
    }
    return finalImage
}

func go(input i: String, width: Int, height: Int) {
    let input: Layer = i.filter {$0.isWholeNumber}.map { Pixel(rawValue: $0)! }
    let size = width * height
    
    let layers = getLayers(pixels: Array(input), layerSize: size)
    
    let checksum = validateImage(layers: layers)
    print(checksum)
    
    let finalImage = decode(layers: layers)
    var str = ""
    for (idx, pixel) in finalImage.enumerated() {
        if idx > 0 && idx % width == 0 {
            str += "\n"
        }
        str += pixel.description
    }
    print(str)
}

guard let fileContents = try? String(contentsOfFile: "input.txt") else {
    fatalError("Cannot open input file")
}

go(input: fileContents, width: 25, height: 6)
