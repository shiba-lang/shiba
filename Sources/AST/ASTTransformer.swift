//
//  ASTTransformer.swift
//  Shiba
//
//  Created by Khoa Le on 02/12/2020.
//

import Foundation

// MARK: - ASTTransform

open class ASTTransformer: ASTVisitor {

  // MARK: Lifecycle

  required public init(context: ASTContext) {
    self.context = context
  }

  // MARK: Open

  open func run(in context: ASTContext) {
    context.diagnostics.forEach(visitPoundDiagnosticExpr)
    context.globals.forEach(visit)
    context.types.forEach(visit)
    context.typeAliases.forEach(visit)
    context.functions.forEach(visit)
    context.extensions.forEach(visit)
  }

  open func visitNumExpr(_ expr: NumExpr) -> Void {}
  open func visitCharExpr(_ expr: CharExpr) -> Void {}
  open func visitFloatExpr(_ expr: FloatExpr) -> Void {}
  open func visitVoidExpr(_ expr: VoidExpr) -> Void {}
  open func visitTypeRefExpr(_ expr: TypeRefExpr) -> Void {}
  open func visitBoolExpr(_ expr: BoolExpr) -> Void {}
  open func visitStringExpr(_ expr: StringExpr) -> Void {}
  open func visitVarExpr(_ expr: VarExpr) -> Void {}
  open func visitPoundFunctionExpr(_ expr: PoundFunctionExpr) -> Void {}
  open func visitNilExpr(_ expr: NilExpr) -> Void {}
  open func visitBreakExpr(_ expr: BreakExpr) -> Void {}
  open func visitContinueExpr(_ expr: ContinueExpr) -> Void {}
  open func visitTypeAliasExpr(_ expr: TypeAliasExpr) -> Void {}

  open func visitParenExpr(_ expr: ParenExpr) -> Void {
    visit(expr.value)
  }

  open func visitTupleExpr(_ expr: TupleExpr) -> Void {
    expr.values.forEach(visit)
  }

  open func visitTupleFieldLookupExpr(_ expr: TupleFieldLookupExpr) -> Void {
    visit(expr.lhs)
  }

  open func visitSizeofExpr(_ expr: SizeofExpr) -> Void {
    expr.value.map(visit)
  }

  open func visitVarAssignExpr(_ expr: VarAssignExpr) -> Void {
    expr.rhs.map(visit)
  }

  open func visitFuncArgumentAssignExpr(_ expr: FuncArgumentAssignExpr) -> Void {
    expr.rhs.map(visit)
  }

  open func visitFuncDeclExpr(_ expr: FuncDeclExpr) -> Void {
    let visitor: () -> Void = {
      for arg in expr.args {
        self.visitFuncArgumentAssignExpr(arg)
      }
      expr.body.map(self.visitCompoundExpr)
    }
    withFunction(expr) {
      if let body = expr.body {
        withScope(body, visitor)
      } else {
        visitor()
      }
    }
  }

  open func visitReturnExpr(_ expr: ReturnExpr) -> Void {
    visit(expr.value)
  }

  open func visitSubscriptExpr(_ expr: SubscriptExpr) -> Void {
    visit(expr.lhs)
    visit(expr.amount)
  }

  open func visitCompoundExpr(_ expr: CompoundExpr) -> Void {
    withScope(expr) {
      expr.exprs.forEach(visit)
    }
  }

  open func visitFuncCallExpr(_ expr: FuncCallExpr) -> Void {
    visit(expr.lhs)
    expr.args.forEach {
      visit($0.val)
    }
  }

  open func visitTypeDeclExpr(_ expr: TypeDeclExpr) -> Void {
    withTypeDecl(expr) {
      for i in expr.initializers { visitFuncDeclExpr(i) }
      for m in expr.methods { visitFuncDeclExpr(m) }
      for f in expr.fields { visitVarAssignExpr(f) }
      if let deinitializer = expr.deinitializer {
        visitFuncDeclExpr(deinitializer)
      }
    }
  }

  open func visitExtensionExpr(_ expr: ExtensionExpr) -> Void {
    for method in expr.methods {
      visitFuncDeclExpr(method)
    }
  }

  open func visitWhileExpr(_ expr: WhileExpr) -> Void {
    visit(expr.condition)
    withBreakTarget(expr) {
      visitCompoundExpr(expr.body)
    }
  }

  open func visitForLoopExpr(_ expr: ForLoopExpr) -> Void {
    expr.initializer.map(visit)
    expr.condition.map(visit)
    expr.incrementer.map(visit)
    withBreakTarget(expr) {
      visit(expr.body)
    }
  }

  open func visitIfExpr(_ expr: IfExpr) -> Void {
    for (condition, body) in expr.blocks {
      visit(condition)
      visitCompoundExpr(body)
    }
    expr.elseBody.map(visit)
  }

  open func visitTernaryExpr(_ expr: TernaryExpr) -> Void {
    visit(expr.condition)
    visit(expr.trueCase)
    visit(expr.falseCase)
  }

  open func visitCaseExpr(_ expr: CaseExpr) -> Void {
    visit(expr.constant)
    visit(expr.body)
  }

  open func visitClosureExpr(_ expr: ClosureExpr) -> Void {
    withClosure(expr) {
      withScope(expr.body) {
        expr.args.forEach(visitFuncArgumentAssignExpr)
        visitCompoundExpr(expr.body)
      }
    }
  }

  open func visitSwitchExpr(_ expr: SwitchExpr) -> Void {
    visit(expr.value)
    for e in expr.cases {
      visit(e)
    }
    expr.defaultBody.map(visitCompoundExpr	)
  }

  open func visitInfixOperatorExpr(_ expr: InfixOperatorExpr) -> Void {
    visit(expr.lhs)
    visit(expr.rhs)
  }

  open func visitPrefixOperatorExpr(_ expr: PrefixOperatorExpr) -> Void {
    visit(expr.rhs)
  }

  open func visitFieldLookupExpr(_ expr: FieldLookupExpr) -> Void {
    visit(expr.lhs)
  }

  open func withFunction(_ e: FuncDeclExpr, _ f: () -> Void) {
    let oldFunction = currentFunction
    currentFunction = e
    withDeclContext(e, f)
    currentFunction = oldFunction
  }

  open func withTypeDecl(_ e: TypeDeclExpr, _ f: () -> Void) {
    let oldType = currentType
    currentType = e
    withDeclContext(e, f)
    currentType = oldType
  }

  open func withScope(_ e: CompoundExpr, _ f: () -> Void) {
    let oldScope = currentScope
    currentScope = e
    withDeclContext(e, f)
    currentScope = oldScope
  }

  open func withClosure(_ e: ClosureExpr, _ f: () -> Void) {
    let oldClosure = currentClosure
    currentClosure = e
    withDeclContext(e, f)
    currentClosure = oldClosure
  }

  open func withBreakTarget(_ e: Expr, _ f: () -> Void) {
    let oldTarget = currentBreakTarget
    currentBreakTarget = e
    withDeclContext(e, f)
    currentBreakTarget = oldTarget
  }

  open func withDeclContext(_ e: Expr, _ f: () -> Void) {
    let oldContext = declContext
    declContext = e
    f()
    declContext = oldContext
  }

  open func visitPoundDiagnosticExpr(_ expr: PoundDiagnosticExpr) {
    // nothing
  }

  // MARK: Public

  public typealias Result = Void

  public var currentFunction: FuncDeclExpr? = nil
  public var currentType: TypeDeclExpr? = nil
  public var currentScope: CompoundExpr? = nil
  public var currentBreakTarget: Expr? = nil
  public var currentClosure: ClosureExpr? = nil

  public var declContext: Expr? = nil

  public let context: ASTContext

  public func matches(_ t1: DataType?, _ t2: DataType?) -> Bool {
    context.matches(t1, t2)
  }

}
