//
//  Functions.swift
//  Shiba
//
//  Created by Khoa Le on 30/11/2020.
//

import Foundation

// MARK: - FunctionKind

// TODO: - Move to parse

public enum FunctionKind {
  case initializer(type: DataType)
  case deinitializer(type: DataType)
  case method(type: DataType)
  case free
}

// MARK: - Argument

public struct Argument: Equatable {

  // MARK: Lifecycle

  public init(val: ValExpr, label: Identifier? = nil) {
    self.label = label
    self.val = val
  }

  // MARK: Public

  public let label: Identifier?
  public let val: ValExpr

}

public func ==(lhs: Argument, rhs: Argument) -> Bool {
  lhs.label == rhs.label
}

// MARK: - FuncDeclExpr

// fn <id>(<id>: <type-id>) -> <type-id> { <expr>* }
public class FuncDeclExpr: DeclExpr {

  // MARK: Lifecycle

  public init(
    name: Identifier,
    returnType: TypeRefExpr,
    args: [FuncArgumentAssignExpr],
    kind: FunctionKind = .free,
    body: CompoundExpr? = nil,
    attributes: [DeclAccessKind] = [],
    hasVarArgs: Bool = false,
    sourceRange: SourceRange? = nil
  ) {
    self.args = args
    self.body = body
    self.returnType = returnType
    self.kind = kind
    self.hasVarArgs = hasVarArgs
    let function: DataType = .function(
      args: args.map { $0.type },
      returnType: returnType.type!
    )
    super.init(
      name: name,
      type: function,
      attributes: attributes,
      sourceRange: sourceRange
    )
  }

  // MARK: Public

  public let args: [FuncArgumentAssignExpr]
  public let body: CompoundExpr?
  public let returnType: TypeRefExpr
  public let hasVarArgs: Bool
  public let kind: FunctionKind

  public var isInitializer: Bool {
    if case .initializer = kind { return true }
    return false
  }

  public var isDeinitializer: Bool {
    if case .deinitializer = kind { return true }
    return false
  }

  public var parentType: DataType? {
    switch kind {
    case .initializer(let type), .method(let type), .deinitializer(let type):
      return type
    case .free:
      return nil
    }
  }

  public var hasImplicitSelf: Bool {
    guard let first = args.first else { return false }
    return first.isImplicitSelf
  }

  public var formattedName: String {
    var str = ""
    if let methodType = parentType {
      str += "\(methodType)"
    }
    str += "\(name)("
    for (idx, arg) in args.enumerated() where !arg.isImplicitSelf {
      var names = [String]()
      if let extern = arg.externalName {
        names.append(extern.name)
      } else {
        names.append("_")
      }
      if names.first != arg.name.name {
        names.append(arg.name.name)
      }
      str += names.joined(separator: " ")
      str += ": \(arg.type)"

      if idx != args.count - 1 || hasVarArgs {
        str += ", "
      }
    }

    if hasVarArgs {
      str += "_: ..."
    }

    str += ")"
    if returnType != .void {
      str += " -> "
      str += "\(returnType.type!)"
    }
    return str
  }

  public func addingImplicitSelf(_ type: DataType) -> FuncDeclExpr {
    var args = self.args
    let typeName = Identifier(name: "\(type)")
    let typeRef = TypeRefExpr(type: type, name: typeName)
    let arg = FuncArgumentAssignExpr(name: "self", type: typeRef)
    arg.isImplicitSelf = true
    arg.isMutable = has(attribute: .mutating)
    args.insert(arg, at: 0)
    return FuncDeclExpr(
      name: name,
      returnType: returnType,
      args: args,
      kind: kind,
      body: body,
      attributes: Array(attributes),
      hasVarArgs: hasVarArgs,
      sourceRange: sourceRange
    )
  }

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? FuncDeclExpr else { return false }
    return name == expr.name &&
      returnType == expr.returnType &&
      args == expr.args &&
      body == expr.body
  }
}

// MARK: - FuncCallExpr

public class FuncCallExpr: ValExpr {

  // MARK: Lifecycle

  public init(lhs: ValExpr, args: [Argument], sourceRange: SourceRange? = nil) {
    self.lhs = lhs
    self.args = args
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let lhs: ValExpr
  public let args: [Argument]
  public var decl: FuncDeclExpr? = nil

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? FuncCallExpr else { return false }
    return lhs == expr.lhs && args == expr.args
  }
}

// MARK: - FuncArgumentAssignExpr

public class FuncArgumentAssignExpr: VarAssignExpr {

  // MARK: Lifecycle

  public init(
    name: Identifier,
    type: TypeRefExpr,
    externalName: Identifier? = nil,
    rhs: ValExpr? = nil,
    sourceRange: SourceRange? = nil
  ) {
    self.externalName = externalName
    super.init(
      name: name,
      typeRef: type,
      rhs: rhs,
      isMutable: false,
      sourceRange: sourceRange
    )
  }

  // MARK: Public

  public var isImplicitSelf = false
  public let externalName: Identifier?

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? FuncArgumentAssignExpr else { return false }
    return name == expr.name
      && externalName == expr.externalName
      && rhs == expr.rhs
  }
}

// MARK: - ReturnExpr

// return <expr>;
public class ReturnExpr: Expr {

  // MARK: Lifecycle

  public init(value: ValExpr, sourceRange: SourceRange? = nil) {
    self.value = value
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let value: ValExpr

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? ReturnExpr else { return false }
    return value == expr.value
  }
}

// MARK: - ClosureExpr

public class ClosureExpr: ValExpr {

  // MARK: Lifecycle

  public init(
    args: [FuncArgumentAssignExpr],
    returnType: TypeRefExpr,
    body: CompoundExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.args = args
    self.returnType = returnType
    self.body = body
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let args: [FuncArgumentAssignExpr]
  public let returnType: TypeRefExpr
  public let body: CompoundExpr

  private(set) public var captures = Set<Expr>()

  public func add(capture: Expr) {
    captures.insert(capture)
  }

}
