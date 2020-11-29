//
//  Operators.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

public enum BuiltinOperator: String, CustomStringConvertible {
  case plus = "+"
  case minus = "-"
  case star = "*"
  case divide = "/"
  case mod = "%"
  case assign = "="
  case equalTo = "==="
  case notEqualTo = "!=="
  case lessThan = "<"
  case lessThanOrEqual = "<="
  case greatherThan = ">"
  case greatherThanOrEqual = ">="
  case and = "&&"
  case or = "||"
  case xor = "^"
  case ampersand = "&"
  case not = "!"
  case bitwiseOr = "|"
  case bitwiseNot = "~"
  case leftShift = "<<"
  case rightShift = ">>"
  case plusAssign = "+="
  case minusAssign = "-="
  case timesAssign = "*="
  case divideAssign = "/="
  case modAssign = "%="
  case andAssign = "&="
  case orAssign = "|="
  case xorAssign = "^="
  case rightShiftAssign = ">>="
  case leftShiftAssign = "<<="

  // MARK: Public

  public var description: String {
    rawValue
  }
}