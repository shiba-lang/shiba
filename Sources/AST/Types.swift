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

  public func ref() -> TypeRefExpr {
    TypeRefExpr(type: self, name: Identifier(name: "\(self)"))
  }

}

public func ==(lhs: DataType, rhs: DataType) -> Bool {
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

  // MARK: Lifecycle

  public init(
    name: Identifier,
    fields: [VarAssignExpr],
    methods: [FuncDeclExpr] = [],
    initializers: [FuncDeclExpr] = [],
    attributes: [DeclAccessKind] = [],
    deinit: FuncDeclExpr? = nil,
    sourceRange: SourceRange? = nil
  ) {
    self.fields = fields
    self.initializers = initializers
    let type = DataType(name: name.name)
    deinitializer = `deinit`?.addingImplicitSelf(type)
    let synthInit = TypeDeclExpr.synthesizeInitializer(
      fields: fields,
      name: name,
      attributes: attributes
    )
    self.initializers.append(synthInit)
    super.init(
      name: name,
      type: type,
      attributes: attributes,
      sourceRange: sourceRange
    )

    methods.forEach {
      self.addMethod($0, named: $0.name.name)
    }

    fields.forEach { field in
      fieldDict[field.name.name] = field.type
    }
  }

  // MARK: Public

  private(set) public var fields: [VarAssignExpr]
  private(set) public var methods = [FuncDeclExpr]()
  private(set) public var initializers = [FuncDeclExpr]()
  public let deinitializer: FuncDeclExpr?

  public var isIndirect: Bool {
    has(attribute: .indirect)
  }

  public static func synthesizeInitializer(
    fields: [VarAssignExpr],
    name: Identifier,
    attributes: [DeclAccessKind]
  ) -> FuncDeclExpr {
    let type = DataType(name: name.name)
    let typeRef = TypeRefExpr(type: type, name: name)
    let initFields = fields.map { field in
      FuncArgumentAssignExpr(
        name: field.name,
        type: field.typeRef!,
        externalName: field.name
      )
    }
    return FuncDeclExpr(
      name: name,
      returnType: typeRef,
      args: initFields,
      kind: .initializer(type: type),
      body: CompoundExpr(exprs: []),
      attributes: attributes
    )
  }

  public func indexOf(fieldName: Identifier) -> Int? {
    fields.firstIndex { field in
      field.name == fieldName
    }
  }

  public func addMethod(_ expr: FuncDeclExpr, named name: String) {
    let decl = expr.hasImplicitSelf ? expr : expr.addingImplicitSelf(type)
    methods.append(decl)
    var methods = methodDict[name] ?? []
    methods.append(decl)
    methodDict[name] = methods
  }

  public func addInitializzer(_ expr: FuncDeclExpr) {
    initializers.append(expr)
  }

  public func addField(_ field: VarAssignExpr) {
    fields.append(field)
    fieldDict[field.name.name] = field.type
  }

  public func methods(named name: String) -> [FuncDeclExpr] {
    methodDict[name] ?? []
  }

  public func field(named name: String) -> VarAssignExpr? {
    for field in fields where field.name.name == name {
      return field
    }
    return nil
  }

  public func typeOf(_ field: String) -> DataType? {
    fieldDict[field]
  }

  public func createRef() -> TypeRefExpr {
    TypeRefExpr(type: type, name: name)
  }

  public override func equals(_ rhs: Expr) -> Bool {
    guard let rhs = rhs as? TypeDeclExpr,
          type == rhs.type,
          fields == rhs.fields,
          methods == rhs.methods else { return false }
    return true
  }

  // MARK: Private

  private var fieldDict = [String: DataType]()
  private var methodDict = [String: [FuncDeclExpr]]()

}

// MARK: - TypeAliasExpr

public class TypeAliasExpr: DeclRefExpr<TypeDeclExpr> {

  // MARK: Lifecycle

  public init(
    name: Identifier,
    bound: TypeRefExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.name = name
    self.bound = bound
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let name: Identifier
  public let bound: TypeRefExpr

  public override func equals(_ rhs: Expr) -> Bool {
    guard let rhs = rhs as? TypeAliasExpr else { return false }
    return name == rhs.name && bound == rhs.bound
  }
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

// MARK: - FieldLookupExpr

public class FieldLookupExpr: ValExpr {

  // MARK: Lifecycle

  public init(lhs: ValExpr, name: Identifier, sourceRange: SourceRange? = nil) {
    self.lhs = lhs
    self.name = name
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let lhs: ValExpr
  public var decl: Expr? = nil
  public var typeDecl: TypeDeclExpr? = nil
  public let name: Identifier

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
