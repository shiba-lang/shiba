//
//  Statements.swift
//  Shiba
//
//  Created by Khoa Le on 30/11/2020.
//

import Foundation

// MARK: - VarAssignExpr

public class VarAssignExpr: DeclExpr {

  // MARK: Lifecycle

  public init(
    name: Identifier,
    typeRef: TypeRefExpr?,
    rhs: ValExpr? = nil,
    containingTypeDecl: TypeDeclExpr? = nil,
    attributes: [DeclAccessKind] = [],
    isMutable: Bool = true,
    sourceRange: SourceRange? = nil
  ) {
    precondition(rhs != nil || typeRef != nil)
    self.rhs = rhs
    self.typeRef = typeRef
    self.containingTypeDecl = containingTypeDecl
    self.isMutable = isMutable
    super.init(
      name: name,
      type: typeRef?.type ?? .void,
      attributes: attributes,
      sourceRange: sourceRange
    )
  }

  // MARK: Public

  public let rhs: ValExpr?
  public var typeRef: TypeRefExpr?
  public var containingTypeDecl: TypeDeclExpr?
  public var isMutable: Bool

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? VarAssignExpr,
          name == expr.name,
          type == expr.type,
          rhs == expr.rhs else
    {
      return false
    }
    return true
  }
}

// MARK: - CompoundExpr

public class CompoundExpr: Expr {

  // MARK: Lifecycle

  public init(exprs: [Expr], sourceRange: SourceRange? = nil) {
    self.exprs = exprs
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let exprs: [Expr]
  public var hasReturn = false

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? CompoundExpr else { return false }
    return exprs == expr.exprs
  }
}

// MARK: - BranchExpr

public class BranchExpr: Expr {

  // MARK: Lifecycle

  public init(
    condition: ValExpr,
    body: CompoundExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.condition = condition
    self.body = body
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let condition: ValExpr
  public let body: CompoundExpr

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? BranchExpr else { return false }
    return condition == expr.condition && body == expr.body
  }
}

// MARK: - IfExpr

public class IfExpr: Expr {

  // MARK: Lifecycle

  public init(
    blocks: [(ValExpr, CompoundExpr)],
    elseBody: CompoundExpr?,
    sourceRange: SourceRange? = nil
  ) {
    self.blocks = blocks
    self.elseBody = elseBody
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let blocks: [(ValExpr, CompoundExpr)]
  public let elseBody: CompoundExpr?

}

// MARK: - WhileExpr

public class WhileExpr: BranchExpr {}

// MARK: - ForLoopExpr

public class ForLoopExpr: Expr {

  // MARK: Lifecycle

  public init(
    initializer: Expr?,
    condition: ValExpr?,
    incrementer: Expr?,
    body: CompoundExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.initializer = initializer
    self.condition = condition
    self.incrementer = incrementer
    self.body = body
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let initializer: Expr?
  public let condition: ValExpr?
  public let incrementer: Expr?
  public let body: CompoundExpr

}

// MARK: - CaseExpr

public class CaseExpr: Expr {

  // MARK: Lifecycle

  public init(
    constant: ConstantExpr,
    body: CompoundExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.constant = constant
    self.body = body
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let constant: ConstantExpr
  public let body: CompoundExpr

}

// MARK: - SwitchExpr

public class SwitchExpr: Expr {

  // MARK: Lifecycle

  public init(
    value: ValExpr,
    cases: [CaseExpr],
    defaultBody: CompoundExpr? = nil,
    sourceRange: SourceRange? = nil
  ) {
    self.value = value
    self.cases = cases
    self.defaultBody = defaultBody
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let value: ValExpr
  public let cases: [CaseExpr]
  public let defaultBody: CompoundExpr?

}

// MARK: - BreakExpr

public class BreakExpr: Expr {
  public override func equals(_ expr: Expr) -> Bool {
    expr is BreakExpr
  }
}

// MARK: - ContinueExpr

public class ContinueExpr: Expr {
  public override func equals(_ expr: Expr) -> Bool {
    expr is ContinueExpr
  }
}

// MARK: - PoundDiagnosticExpr

public class PoundDiagnosticExpr: Expr {

  // MARK: Lifecycle

  public init(
    isError: Bool,
    content: StringExpr,
    sourceRange: SourceRange? = nil
  ) {
    self.isError = isError
    self.content = content
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let isError: Bool
  public let content: StringExpr

  public var text: String {
    content.text
  }
}

// MARK: - ExtensionExpr

public class ExtensionExpr: DeclRefExpr<TypeDeclExpr> {

  // MARK: Lifecycle

  public init(
    type: TypeRefExpr,
    methods: [FuncDeclExpr],
    sourceRange: SourceRange? = nil
  ) {
    self.methods = methods.map { $0.addingImplicitSelf(type.type!) }
    typeRef = type
    super.init(sourceRange: sourceRange)
    self.type = type.type!
  }

  // MARK: Public

  public let methods: [FuncDeclExpr]
  public let typeRef: TypeRefExpr

  public override func equals(_ expr: Expr) -> Bool {
    guard let expr = expr as? ExtensionExpr else { return false }
    return methods == expr.methods
  }
}
