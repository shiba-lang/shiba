//
//  TypeExprs.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

// MARK: - FloatingPointType

public enum FloatingPointType {
  case float
  case double
  case float80
}

// MARK: - DataType

public enum DataType: CustomStringConvertible, Hashable {
  case int(width: Int, signed: Bool)
  case floating(type: FloatingPointType)
  case bool
  case void
  case custom(name: String)
  case any

  indirect case function(args: [DataType], returnType: DataType)
  indirect case pointer(type: DataType)
  indirect case tuple(fields: [DataType])

  // MARK: Lifecycle

  public init(name: String) {
    switch name {
    case "Int8": self = .int8
    case "Int16": self = .int16
    case "Int32": self = .int32
    case "Int": self = .int64
    case "Bool": self = .bool
    case "Void": self = .void
    case "Float": self = .float
    case "Float80": self = .float80
    case "Double": self = .double
    case "Any": self = .any
    default: self = .custom(name: name)
    }
  }

  // MARK: Public

  public static let int64: DataType = .int(width: 64, signed: true)
  public static let int32: DataType = .int(width: 32, signed: true)
  public static let int16: DataType = .int(width: 16, signed: true)
  public static let int8: DataType = .int(width: 8, signed: true)
  public static let uint64: DataType = .int(width: 64, signed: false)
  public static let uint32: DataType = .int(width: 32, signed: false)
  public static let uint16: DataType = .int(width: 16, signed: false)
  public static let uint8: DataType = .int(width: 8, signed: false)
  public static let float: DataType = .floating(type: .float)
  public static let double: DataType = .floating(type: .double)
  public static let float80: DataType = .floating(type: .float80)

  public var description: String {
    switch self {
    case .int(width: 64, let signed):
      return "\(signed ? "" : "U")Int"
    case let .int(width, signed):
      return "\(signed ? "" : "U")Int\(width)"
    case .bool: return "Bool"
    case .void: return "Void"
    case let .custom(name): return name
    case let .pointer(type):
      return "*\(type)"
    case let .floating(type):
      switch type {
      case .float: return "Float"
      case .double: return "Double"
      case .float80: return "Float80"
      }
    case let .tuple(fields):
      let fields = fields.map { $0.description }
        .joined(separator: ", ")
      return "(\(fields))"
    case let .function(args, returnType):
      let args = args.map { $0.description }
        .joined(separator: ", ")
      return "(\(args) -> \(returnType)"
    case .any: return "Any"
    }
  }

  public var isPointer: Bool {
    if case .pointer = self { return true }
    return false
  }

  public static func ==(lhs: DataType, rhs: DataType) -> Bool {
    switch (lhs, rhs) {
    case (.int(let lhsWidth, let lhsSigned), .int(let rhsWidth, let rhsSigned)):
      return lhsWidth == rhsWidth && lhsSigned == rhsSigned
    case (.bool, .bool):
      return true
    case (.void, .void):
      return true
    case (.pointer(let lhsType), .pointer(type: let rhsType)):
      return lhsType == rhsType
    case (.any, .any):
      return true
    case (.floating(let lhsDouble), .floating(let rhsDouble)):
      return lhsDouble == rhsDouble
    case (.function(let lhsArgs, let lhsRet), .function(let rhsArgs, let rhsRet)):
      return lhsArgs == rhsArgs && lhsRet == rhsRet
    case (.tuple(let lhsFields), .tuple(let rhsFields)):
      return lhsFields == rhsFields
    case (.custom(let lhsName), .custom(let rhsName)):
      return lhsName == rhsName
    default: return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(description)
    hasher.combine(0x01a13f61)
  }

  public func pointerLevel() -> Int {
    guard case let .pointer(t) = self else {
      return 0
    }
    return t.pointerLevel() + 1
  }

}

// MARK: - DeclExpr

public class DeclExpr: BindingExpr {

  // MARK: Lifecycle

  public init(
    name: Identifier,
    type: DataType,
    attributes: [DeclAccessKind],
    sourceRange: SourceRange?
  ) {
    self.type = type
    self.attributes = Set(attributes)
    super.init(name: name, sourceRange: sourceRange)
  }

  // MARK: Public

  public var type: DataType
  public let attributes: Set<DeclAccessKind>

  public func has(attribute: DeclAccessKind) -> Bool {
    attributes.contains(attribute)
  }

}

// MARK: - TypeDeclExpr

public class TypeDeclExpr: DeclExpr {
  // TODO: - Implement `TypeDeclExpr`
}

// MARK: - DeclRefExpr

public class DeclRefExpr<DeclType: DeclExpr>: ValExpr {

  // MARK: Lifecycle

  public override init(sourceRange: SourceRange?) {
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public weak var decl: DeclType? = nil
}

// MARK: - TypeRefExpr

public class TypeRefExpr: DeclRefExpr<TypeDeclExpr> {

  // MARK: Lifecycle

  public init(type: DataType, name: Identifier, sourceRange: SourceRange? = nil) {
    self.name = name
    super.init(sourceRange: sourceRange)
    self.type = type
  }

  // MARK: Public

  public let name: Identifier
}

// MARK: - FuncTypeRefExpr

public class FuncTypeRefExpr: TypeRefExpr {

  // MARK: Lifecycle

  public init(
    argNames: [TypeRefExpr],
    retName: TypeRefExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.argNames = argNames
    self.retName = retName
    let argTypes = argNames.map { $0.type! }
    let argStrings = argNames.map { $0.name.name }
    var fullName = "(" + argStrings.joined(separator: ", ") + ")"
    if retName != .void {
      fullName += " -> " + retName.name.name
    }
    let fullId = Identifier(name: fullName, range: sourceRange)
    let function: DataType = .function(args: argTypes, returnType: retName.type!)

    super.init(type: function, name: fullId, sourceRange: sourceRange)
  }

  // MARK: Public

  public let argNames: [TypeRefExpr]
  public let retName: TypeRefExpr

}

// MARK: - PointerTypeRefExpr

public class PointerTypeRefExpr: TypeRefExpr {

  // MARK: Lifecycle

  public init(
    pointedTo: TypeRefExpr,
    level: Int,
    sourceRange: SourceRange? = nil
  ) {
    pointed = pointedTo
    let fullName = String(repeating: "*", count: level) + pointedTo.name.name
    let fullId = Identifier(name: fullName, range: sourceRange)
    var type = pointedTo.type!
    for _ in 0..<level {
      type = .pointer(type: type)
    }
    super.init(type: type, name: fullId, sourceRange: sourceRange)
  }

  // MARK: Public

  public let pointed: TypeRefExpr
}

// MARK: - TupleTypeRefExpr

public class TupleTypeRefExpr: TypeRefExpr {

  // MARK: Lifecycle

  public init(fieldNames: [TypeRefExpr], sourceRange: SourceRange? = nil) {
    self.fieldNames = fieldNames
    let argTypes = fieldNames.map { $0.type! }
    let name = fieldNames.map { $0.name.name }
      .joined(separator: ", ")
    let fullname = "(\(name))"
    let fullId = Identifier(name: fullname, range: sourceRange)
    super.init(
      type: .tuple(fields: argTypes),
      name: fullId,
      sourceRange: sourceRange
    )
  }

  // MARK: Public

  public let fieldNames: [TypeRefExpr]
}

public func ==(lhs: TypeRefExpr, rhs: DataType) -> Bool {
  lhs.type == rhs
}

public func !=(lhs: TypeRefExpr, rhs: DataType) -> Bool {
  lhs.type != rhs
}

public func ==(lhs: DataType, rhs: TypeRefExpr) -> Bool {
  lhs == rhs.type
}

public func !=(lhs: DataType, rhs: TypeRefExpr) -> Bool {
  lhs != rhs.type
}
