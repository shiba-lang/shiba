//
//  Lex+String.swift
//  Shiba
//
//  Created by Khoa Le on 27/11/2020.
//

import Foundation

extension String {
  func escaped() -> String {
    var str = ""
    for char in self {
      switch char {
      case "\n": str += "\\n"
      case "\t": str += "\\t"
      case "\"": str += "\\\""
      default: str.append(char)
      }
    }
    return str
  }

  func unescaped() -> String {
    var str = ""
    var nextCharIsEscaped = false
    for char in self {
      if char == "\\" {
        nextCharIsEscaped = true
        continue
      }
      if nextCharIsEscaped {
        switch char {
        case "n": str.append("\n")
        case "t": str.append("\t")
        case "\"": str.append("\"")
        default: str.append(char)
        }
      } else {
        str.append(char)
      }
    }
    return str
  }

	func removing(_ string: String) -> String {
		return replacingOccurrences(of: string, with: "")
	}

	func asNumber() -> Int? {
		let prefixMap = ["0x": 16, "0b": 2, "0o": 8]
		if self.count <= 2 {
			return Int(self, radix: 10)
		}
		let prefixIndex = self.index(startIndex, offsetBy: 2)
		let prefix = String(self[..<prefixIndex])
		guard let radix = prefixMap[prefix] else {
			return Int(removing("_"), radix: 10)
		}

		let suffixIndex = self.index(startIndex, offsetBy: 2)
		let suffix = String(removing("_")[suffixIndex...])
		return Int(suffix, radix: radix)
	}
}
