//
//  ASTContext.swift
//  Shiba
//
//  Created by Khoa Le on 30/11/2020.
//

import Foundation

// MARK: - ASTError

fileprivate enum ASTError: Error, CustomStringConvertible {
  case duplicateVar(name: Identifier)
  case duplicateType(name: Identifier)
  case duplicateFunction(name: Identifier)
  case circularAlias(name: Identifier)
  case invalidMain(got: DataType)
  case duplicateMain

  // MARK: Internal

  var description: String {
    switch self {
    case let .duplicateVar(name):
      return "invalid redeclaration of type '\(name)'"
    case let .duplicateType(name):
      return "invalid redeclaration of variable '\(name)'"
    case let .duplicateFunction(name):
      return "invalid redeclartion of function '\(name)'"
    case let .circularAlias(name):
      return "declaration of '\(name)' is circular"
    case let .invalidMain(type):
      return "invalid main (must be (Int, **Int8) -> Void or () -> Void, got \(type)"
    case .duplicateMain:
      return "only one main function is allowed"
    }
  }
}

// MARK: - Mutability

public enum Mutability {
  case immutable(culprit: Identifier?)
  case mutable
}

// MARK: - MainFuncFlags

public struct MainFuncFlags: OptionSet {

  // MARK: Lifecycle

  public init(rawValue: Int8) {
    self.rawValue = rawValue
  }

  // MARK: Public

  public static var args = MainFuncFlags(rawValue: 1 << 0)
  public static var exitCode = MainFuncFlags(rawValue: 1 << 1)

  public var rawValue: Int8
}

// MARK: - ASTContext

public final class ASTContext {

  // MARK: Lifecycle

  public init(diagnosticEngine: DiagnosticEngine) {
    diag = diagnosticEngine
  }

  // MARK: Public

  public let diag: DiagnosticEngine

  public var functions = [FuncDeclExpr]()
  public var types = [TypeDeclExpr]()
  public var extensions = [ExtensionExpr]()
  public var diagnostics = [PoundDiagnosticExpr]()
  public var globals = [VarAssignExpr]()
  public var typeAliases = [TypeAliasExpr]()

  private(set) public var mainFunction: FuncDeclExpr? = nil
  private(set) public var mainFlags: MainFuncFlags? = nil

  public func error(
    _ err: Error,
    loc: SourceLocation? = nil,
    highlights: [SourceRange?] = []
  ) {
    diag.error(err, loc: loc, highlights: highlights)
  }

  public func warning(
    _ warning: Error,
    loc: SourceLocation? = nil,
    highlights: [SourceRange?] = []
  ) {
    diag.warning("\(warning)", loc: loc, highlights: highlights)
  }

  public func warning(
    _ msg: String,
    loc: SourceLocation? = nil,
    highlights: [SourceRange?] = []
  ) {
    diag.warning(msg, loc: loc, highlights: highlights)
  }

  public func setMain(_ main: FuncDeclExpr) {
    guard mainFunction == nil else {
      error(
        ASTError.duplicateMain,
        loc: main.startLoc(),
        highlights: [main.name.range]
      )
      return
    }

    guard case let .function(args, ret) = main.type else {
      fatalError()
    }

    var flags = MainFuncFlags()
    if ret == .int64 {
      _ = flags.insert(.exitCode)
    }

    if args.count == 2 {
      let pointer: DataType = .pointer(type: .int(width: 8, signed: true))
      if case (.int, pointer) = (args[0], args[1]) {
        _ = flags.insert(.args)
      }
    }

    mainFlags = flags
    let hasInvalidArgs = !args.isEmpty && !flags.contains(.args)
    let hasInvalidRet = ret != .void && !flags.contains(.exitCode)

    if hasInvalidRet || hasInvalidArgs {
      error(
        ASTError.invalidMain(got: main.type),
        loc: main.startLoc(),
        highlights: [main.name.range]
      )
      return
    }
    mainFunction = main
  }

  public func add(_ funcDecl: FuncDeclExpr) {
    functions.append(funcDecl)

    if funcDecl.name == "main" {
      setMain(funcDecl)
    }
    //		let decls = functions(named: funcDecl.name)
    // TODO: - check error sema

    var existing = funcDeclMap[funcDecl.name.name] ?? []
    existing.append(funcDecl)
    funcDeclMap[funcDecl.name.name] = existing
  }

  @discardableResult
  public func add(_ typeDecl: TypeDeclExpr) -> Bool {
    guard decl(for: typeDecl.type) == nil else {
      let err = ASTError.duplicateType(name: typeDecl.name)
      error(err, loc: typeDecl.startLoc(), highlights: [typeDecl.name.range])
      return false
    }
    types.append(typeDecl)
    typeDeclMap[typeDecl.type] = typeDecl
    return true
  }

  @discardableResult
  public func add(_ global: VarAssignExpr) -> Bool {
    guard globalDeclMap[global.name.name] == nil else {
      let err = ASTError.duplicateVar(name: global.name)
      error(err, loc: global.startLoc(), highlights: [global.sourceRange])
      return false
    }
    globals.append(global)
    globalDeclMap[global.name.name] = global
    return true
  }

  public func add(_ extensionExpr: ExtensionExpr) {
    extensions.append(extensionExpr)
  }

  public func add(_ diagnosticExpr: PoundDiagnosticExpr) {
    diagnostics.append(diagnosticExpr)
  }

  @discardableResult
  public func add(_ alias: TypeAliasExpr) -> Bool {
    guard typeAliasMap[alias.name.name] == nil else {
      return false
    }
    if isCircularAlias(alias.bound.type!, visited: [alias.name.name]) {
      let err = ASTError.circularAlias(name: alias.name)
      error(err, loc: alias.name.range?.start, highlights: [alias.name.range])
      return false
    }
    typeAliasMap[alias.name.name] = alias
    typeAliases.append(alias)
    return true
  }

  public func decl(for type: DataType, canonicalized: Bool = true) -> TypeDeclExpr? {
    let root = canonicalized ? canonicalType(type) : type
    return typeDeclMap[root]
  }

  public func canonicalType(_ type: DataType) -> DataType {
    if case .custom(let name) = type {
      if let alias = typeAliasMap[name] {
        return canonicalType(alias.bound.type!)
      }
    }
    if case .function(let args, let returnType) = type {
      var newArgs = [DataType]()
      for arg in args {
        newArgs.append(canonicalType(arg))
      }
      return .function(args: newArgs, returnType: canonicalType(returnType))
    }
    if case .pointer(let subtype) = type {
      return .pointer(type: canonicalType(subtype))
    }
    return type
  }

  public func functions(named name: Identifier) -> [FuncDeclExpr] {
    funcDeclMap[name.name] ?? []
  }

  public func isCircularAlias(_ type: DataType, visited: Set<String>) -> Bool {
    var visited = visited
    if case .custom(let name) = type {
      if visited.contains(name) {
        return true
      }
      visited.insert(name)
      guard let bound = typeAliasMap[name]?.bound.type else { return false }
      return isCircularAlias(bound, visited: visited)
    } else if case .function(let args, let ret) = type {
      for arg in args where isCircularAlias(arg, visited: visited) {
        return true
      }
      return isCircularAlias(ret, visited: visited)
    }
    return false
  }

  // MARK: Private

  private var funcDeclMap = [String: [FuncDeclExpr]]()
  private var typeDeclMap: [DataType: TypeDeclExpr] = [
    // TODO: - Implement UInt, FloatType
    .int8: TypeDeclExpr(name: "Int8", fields: []),
    .int16: TypeDeclExpr(name: "Int16", fields: []),
    .int32: TypeDeclExpr(name: "Int32", fields: []),
    .int64: TypeDeclExpr(name: "Int", fields: []),
    .bool: TypeDeclExpr(name: "Bool", fields: []),
    .void: TypeDeclExpr(name: "Void", fields: []),
  ]
  private var globalDeclMap = [String: VarAssignExpr]()
  private var typeAliasMap = [String: TypeAliasExpr]()

}
