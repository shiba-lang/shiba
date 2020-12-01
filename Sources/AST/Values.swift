//
//  Values.swift
//  Shiba
//
//  Created by Khoa Le on 30/11/2020.
//

import Foundation

// MARK: - ValExpr

public class ValExpr: Expr {
  public var type: DataType? = nil
}

// MARK: - ConstantExpr

public class ConstantExpr: ValExpr {

  // MARK: Lifecycle

  public override init(sourceRange: SourceRange? = nil) {
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public var text: String {
    ""
  }
}

// MARK: - VoidExpr

public class VoidExpr: ValExpr {

  // MARK: Lifecycle

  public override init(sourceRange: SourceRange? = nil) {
    super.init(sourceRange: sourceRange)
    type = .void
  }

  // MARK: Public

  public override func equals(_ expr: Expr) -> Bool {
    expr is VoidExpr
  }
}

// MARK: - NilExpr

public class NilExpr: ValExpr {

  // MARK: Lifecycle

  public override init(sourceRange: SourceRange? = nil) {
    super.init(sourceRange: sourceRange)
    type = .pointer(type: .int8)
  }

  // MARK: Public

  public override func equals(_ expr: Expr) -> Bool {
    guard let other = expr as? NilExpr else { return false }
    return other.type == type
  }
}

// MARK: - NumExpr

public class NumExpr: ConstantExpr {

  // MARK: Lifecycle

  public init(value: Int64, raw: String, sourceRange: SourceRange? = nil) {
    self.value = value
    self.raw = raw
    super.init(sourceRange: sourceRange)
    type = .int64
  }

  // MARK: Public

  public let value: Int64
  public let raw: String

  public override var text: String {
    "\(value)"
  }

  public override func equals(_ expr: Expr) -> Bool {
    guard let other = expr as? NumExpr else { return false }
    return other.value == value
  }
}

// MARK: - ParenExpr

public class ParenExpr: ValExpr {

  // MARK: Lifecycle

  public init(value: ValExpr, sourceRange: SourceRange? = nil) {
    self.value = value
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let value: ValExpr

  // MARK: Internal

  var rootExpr: ValExpr {
    if let paren = value as? ParenExpr {
      return paren.rootExpr
    }
    return value
  }
}

// MARK: - TupleExpr

public class TupleExpr: ValExpr {

  // MARK: Lifecycle

  public init(values: [ValExpr], sourceRange: SourceRange? = nil) {
    self.values = values
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let values: [ValExpr]

  public override var type: DataType? {
    get {
      var fieldTypes = [DataType]()
      for v in values {
        guard let type = v.type else { return nil }
        fieldTypes.append(type)
      }
      return .tuple(fields: fieldTypes)
    }
    set {
      fatalError("cannot set type on tuple expr")
    }
  }
}

// MARK: - TupleFieldLookupExpr

public class TupleFieldLookupExpr: ValExpr {

  // MARK: Lifecycle

  init(
    lhs: ValExpr,
    field: Int,
    fieldRange: SourceRange,
    sourceRange: SourceRange? = nil
  ) {
    self.lhs = lhs
    self.field = field
    self.fieldRange = fieldRange
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let lhs: ValExpr
  public let field: Int
  public let fieldRange: SourceRange

  public override func equals(_ rhs: Expr) -> Bool {
    guard let rhs = rhs as? TupleFieldLookupExpr,
          field == rhs.field,
          lhs == rhs.lhs else
    {
      return false
    }
    return true
  }

  // MARK: Internal

  var decl: Expr? = nil

}

// MARK: - FloatExpr

public class FloatExpr: ConstantExpr {

  // MARK: Lifecycle

  public init(value: Double, sourceRange: SourceRange? = nil) {
    self.value = value
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let value: Double

  public override var type: DataType? {
    get {
      .double
    }
    set {}
  }

  public override var text: String {
    "\(value)"
  }

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? FloatExpr else { return false }
    return value == expr.value
  }

}

// MARK: - BoolExpr

public class BoolExpr: ConstantExpr {

  // MARK: Lifecycle

  public init(value: Bool, sourceRange: SourceRange? = nil) {
    self.value = value
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let value: Bool

  public override var type: DataType? {
    get { .bool } set {}
  }

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? BoolExpr else { return false }
    return value == expr.value
  }
}

// MARK: - StringExpr

public class StringExpr: ConstantExpr {

  // MARK: Lifecycle

  public init(value: String, sourceRange: SourceRange? = nil) {
    self.value = value
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let value: String

  public override var type: DataType? {
    get { .pointer(type: .int8) } set {}
  }

  public override var text: String {
    value
  }
}

// MARK: - VarExpr

public class VarExpr: ValExpr {

  // MARK: Lifecycle

  public init(name: Identifier, sourceRange: SourceRange? = nil) {
    self.name = name
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let name: Identifier
  public let isTypeVar = false
  public var isSelf = false
  public var decl: DeclExpr? = nil

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? VarExpr else { return false }
    return name == expr.name
  }
}

// MARK: - PoundFunctionExpr

public class PoundFunctionExpr: StringExpr {
  public init(sourceRange: SourceRange? = nil) {
    super.init(value: "", sourceRange: sourceRange)
  }
}

// MARK: - CharExpr

public class CharExpr: ConstantExpr {

  // MARK: Lifecycle

  public init(value: UInt8, sourceRange: SourceRange? = nil) {
    self.value = value
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let value: UInt8

  public override var type: DataType? {
    get { .int8 } set {}
  }

  public override var text: String {
    "\(value)"
  }
}

// MARK: - SubscriptExpr

public class SubscriptExpr: ValExpr {

  // MARK: Lifecycle

  public init(lhs: ValExpr, amount: ValExpr, sourceRange: SourceRange? = nil) {
    self.lhs = lhs
    self.amount = amount
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let lhs: ValExpr
  public let amount: ValExpr

}

// MARK: - TernaryExpr

public class TernaryExpr: ValExpr {

  // MARK: Lifecycle

  public init(
    condition: ValExpr,
    trueCase: ValExpr,
    falseCase: ValExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.condition = condition
    self.trueCase = trueCase
    self.falseCase = falseCase
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let condition: ValExpr
  public let trueCase: ValExpr
  public let falseCase: ValExpr
}

// MARK: - SizeofExpr

public class SizeofExpr: ValExpr {

  // MARK: Lifecycle

  init(value: ValExpr, sourceRange: SourceRange? = nil) {
    self.value = value
    super.init(sourceRange: sourceRange)
    type = .int64
  }

  // MARK: Public

  public var value: ValExpr?
  public var valueType: DataType?
}
