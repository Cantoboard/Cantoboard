//
//  main.swift
//  FilterMissingGlyph
//
//  Created by Alex Man on 2/21/21.
//

import Foundation
import System
import AppKit

let fonts = [
    NSFont(name: "PingFang HK", size: 12)!,
    NSFont(name: "PingFang TC", size: 12)!,
    NSFont(name: "PingFang SC", size: 12)!,
    // NSFont(name: "Heiti TC", size: 12)!,
    // NSFont(name: "Heiti SC", size: 12)!
]
var output: [String] = []
main()

func main() {
    let arguments = CommandLine.arguments
    if arguments.count != 3 {
        let exePath = URL(fileURLWithPath: arguments[0])
        print("Usage: \(exePath.lastPathComponent) [--line|--opencc] <filename>")
        return
    }
    
    let fileToFilter = URL(fileURLWithPath: arguments[2])
    let mode = arguments[1]
    switch mode {
    case "--line": filterLineByLine(filePath: fileToFilter)
    case "--opencc": filterOpenCCDict(filePath: fileToFilter)
    default:
        print("Unknown mode: \(mode)")
        return
    }
    
    let contentOfFile = output.joined(separator: "\n") + "\n"
    try! contentOfFile.write(to: fileToFilter, atomically: true, encoding: .utf8)
}

func filterLineByLine(filePath: URL) {
    let lines = try! String(contentsOf: filePath).components(separatedBy: .newlines)
    
    var i = 0

    for line in lines {
        let lineWithoutWhitespaces = line.filter{ !$0.isWhitespace }
        if !lineWithoutWhitespaces.isEmpty && canStringBeEncoded(lineWithoutWhitespaces) { output.append(line) }
        i += 1
        // if i > 50 { break }
    }
}

func filterOpenCCDict(filePath: URL) {
    let lines = try! String(contentsOf: filePath).components(separatedBy: .newlines)
    
    var i = 0

    for line in lines {
        let parsedLine = line.split(separator: "\t")
        if parsedLine.count < 2 { continue }
        let src = String(parsedLine[0])
        
        if !canStringBeEncoded(src) { continue }
        
        let mappedWords = parsedLine[1].split(separator: " ").map({ String($0) })
        let filteredMappedWords = mappedWords.filter({ canStringBeEncoded($0) }).joined(separator: " ")
        
        if filteredMappedWords.count == 0 { continue }
        
        output.append("\(src)\t\(filteredMappedWords)")
        i += 1
        // if i > 50 { break }
    }
}

func canStringBeEncoded(_ str: String) -> Bool {
    return canStringBeEncoded(str as NSString)
}

func canStringBeEncoded(_ nstr: NSString) -> Bool {
    var buf = Array<unichar>(repeating: 0, count: nstr.length)
    nstr.getCharacters(&buf)
    var glyphs: [CGGlyph] = Array(repeating: 0, count: nstr.length)
    
    let canEncode = fonts.contains(where: { CTFontGetGlyphsForCharacters($0, &buf, &glyphs, glyphs.count) })
    return canEncode
}
