//
//  Operators.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - BuiltinOperator

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
  case greaterThan = ">"
  case greaterThanOrEqual = ">="
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
  case `as` = "as"

  // MARK: Public

  public var description: String {
    rawValue
  }

  public var isPrefix: Bool {
    self == .bitwiseNot || self == .not ||
      self == .minus || self == .ampersand ||
      self == .star
  }

  public var isInfix: Bool {
    self != .bitwiseNot && self != .not
  }

  public var associatedOp: BuiltinOperator? {
    switch self {
    case .modAssign: return .mod
    case .plusAssign: return .plus
    case .timesAssign: return .star
    case .divideAssign: return .divide
    case .minusAssign: return .minus
    case .leftShiftAssign: return .leftShift
    case .rightShiftAssign: return .rightShift
    case .andAssign: return .and
    case .orAssign: return .or
    case .xorAssign: return .xor
    default: return nil
    }
  }

  public var isCompoundAssign: Bool {
    associatedOp != nil
  }

  public var isAssign: Bool {
    isCompoundAssign || self == .assign
  }

  public var infixPrecedence: Int {
    switch self {
    case .as: return 200

    case .leftShift: return 190
    case .rightShift: return 190

    case .star: return 180
    case .divide: return 180
    case .mod: return 180
    case .ampersand: return 180

    case .plus: return 170
    case .minus: return 170
    case .xor: return 170
    case .bitwiseOr: return 170

    case .equalTo: return 160
    case .notEqualTo: return 160
    case .lessThan: return 160
    case .lessThanOrEqual: return 160
    case .greaterThan: return 160
    case .greaterThanOrEqual: return 160

    case .and: return 150

    case .or: return 140

    case .assign: return 130
    case .plusAssign: return 130
    case .minusAssign: return 130
    case .timesAssign: return 130
    case .divideAssign: return 130
    case .modAssign: return 130
    case .andAssign: return 130
    case .orAssign: return 130
    case .xorAssign: return 130
    case .rightShiftAssign: return 130
    case .leftShiftAssign: return 130

    // prefix-only
    case .not: return 999
    case .bitwiseNot: return 999
    }
  }
}

// MARK: - PrefixOperatorExpr

public class PrefixOperatorExpr: ValExpr {

  // MARK: Lifecycle

  public init(
    op: BuiltinOperator,
    rhs: ValExpr,
    opRange: SourceRange? = nil,
    sourceRange: SourceRange? = nil
  ) {
    self.rhs = rhs
    self.op = op
    self.opRange = opRange
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let op: BuiltinOperator
  public let opRange: SourceRange?
  public let rhs: ValExpr

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? PrefixOperatorExpr else { return false }
    return op == expr.op && rhs == expr.rhs
  }

  public func type(forArgType argType: DataType) -> DataType? {
    switch (op, argType) {
    case (.minus, .int): return argType
    case (.minus, .floating): return argType
    case (.star, .pointer(let type)): return type
    case (.not, .bool): return .bool
    case (.ampersand, let type): return .pointer(type: type)
    case (.bitwiseNot, .int): return argType
    default: return nil
    }
  }
}

// MARK: - InfixOperatorExpr

public class InfixOperatorExpr: ValExpr {

  // MARK: Lifecycle

  init(
    op: BuiltinOperator,
    lhs: ValExpr,
    rhs: ValExpr,
    opRange: SourceRange? = nil,
    sourceRange: SourceRange? = nil
  ) {
    self.lhs = lhs
    self.rhs = rhs
    self.op = op
    self.opRange = opRange
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let op: BuiltinOperator
  public let opRange: SourceRange?

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? InfixOperatorExpr else { return false }
    return op == expr.op && rhs == expr.rhs && lhs == expr.lhs
  }

  public func type(forArgType argType: DataType) -> DataType? {
    if op.isAssign { return argType }
    switch (op, argType) {
    case (.plus, .int): return argType
    case (.plus, .floating): return argType
    case (.plus, .pointer): return argType
    case (.minus, .int): return argType
    case (.minus, .floating): return argType
    case (.minus, .pointer): return .int64
    case (.star, .int): return argType
    case (.star, .floating): return argType
    case (.star, .pointer): return .int64
    case (.divide, .int): return argType
    case (.divide, .floating): return argType
    case (.mod, .int): return argType

    case (.equalTo, .int): return .bool
    case (.equalTo, .pointer): return .bool
    case (.equalTo, .floating): return .bool
    case (.equalTo, .bool): return .bool

    case (.notEqualTo, .int): return .bool
    case (.notEqualTo, .floating): return .bool
    case (.notEqualTo, .pointer): return .bool
    case (.notEqualTo, .bool): return .bool

    case (.lessThan, .int): return .bool
    case (.lessThan, .pointer): return .bool
    case (.lessThan, .floating): return .bool

    case (.lessThanOrEqual, .int): return .bool
    case (.lessThanOrEqual, .pointer): return .bool
    case (.lessThanOrEqual, .floating): return .bool

    case (.greaterThan, .int): return .bool
    case (.greaterThan, .pointer): return .bool
    case (.greaterThan, .floating): return .bool

    case (.greaterThanOrEqual, .int): return .bool
    case (.greaterThanOrEqual, .pointer): return .bool
    case (.greaterThanOrEqual, .floating): return .bool

    case (.and, .bool): return .bool
    case (.or, .bool): return .bool
    case (.xor, .int): return argType
    case (.xor, .bool): return .bool
    case (.bitwiseOr, .int): return argType
    case (.ampersand, .int): return argType
    case (.leftShift, .int): return argType
    case (.rightShift, .int): return argType
    default: return nil
    }
  }

  // MARK: Internal

  let lhs: ValExpr
  let rhs: ValExpr

}


