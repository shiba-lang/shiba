//
//  main.swift
//  shiba-demangle
//
//  Created by Khoa Le on 08/12/2020.
//

import Foundation

func demangle(_ symbol: String) -> String? {
  symbol.withCString { (cStr) -> String? in
    guard let demangled = shiba_demangle(cStr) else {
      return nil
    }
    defer {
      free(demangled)
    }
    return String(cString: demangled)
  }
}

func demangleArgs() {
  for arg in CommandLine.arguments.dropFirst() {
    if let demangled = demangle(arg) {
      print("\(arg) => \(demangled)")
    } else {
      print("could not demangle \(arg)")
    }
  }
}

// MARK: - DemangleRegex

class DemangleRegex: NSRegularExpression {

  // MARK: Lifecycle

  convenience init() {
    try! self.init(pattern: "_W\\w+", options: [])
  }

  // MARK: Internal

  override func replacementString(
    for result: NSTextCheckingResult,
    in string: String,
    offset: Int,
    template templ: String
  ) -> String {
    let res = result.adjustingRanges(offset: offset)
    let start = string.index(string.startIndex, offsetBy: res.range.location)
    let end = string.index(start, offsetBy: res.range.length)
    let range = start..<end
    let symbol = String(string[range])
    return demangle(symbol) ?? symbol
  }
}

func demangleStdin() {
  let r = DemangleRegex()
  while let line = readLine() {
    let string = (line as NSString).mutableCopy() as! NSMutableString
    r.replaceMatches(
      in: string,
      options: [],
      range: NSRange(location: 0, length: string.length),
      withTemplate: ""
    )
    print(string)
  }
}

if CommandLine.argc > 1 {
  demangleArgs()
} else {
  demangleStdin()
}
