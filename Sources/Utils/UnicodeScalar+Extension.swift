//
//  UnicodeScalar+Extension.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

extension UnicodeScalar {
  static let operatorChars: Set<UnicodeScalar> = Set("+-*/%=~<>^|&!".unicodeScalars)

  var isNumeric: Bool {
    isnumber(Int32(value)) != 0
  }

  var isSpace: Bool {
    isspace(Int32(value)) != 0 && self != "\n"
  }

  var isLineSeparator: Bool {
    self == "\n" || self == ";"
  }

  var isIdentifier: Bool {
    isalnum(Int32(value)) != 0 || self == "_"
  }

  var isOperator: Bool {
    UnicodeScalar.operatorChars.contains(self)
  }

  var isHexadecimal: Bool {
    ishexnumber(Int32(value)) != 0
  }
}
