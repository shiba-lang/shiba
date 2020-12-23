//
//  ASTPrinter.swift
//  Shiba
//
//  Created by Khoa Le on 07/12/2020.
//

import Foundation

public final class ASTPrinter<StreamType: TextOutputStream>: ASTTransformer {

  // MARK: Lifecycle

  public init(stream: inout StreamType, context: ASTContext) {
    self.stream = stream
    super.init(context: context)
  }

  required public init(context: ASTContext) {
    fatalError("init(context:) has not been implemented")
  }

  // MARK: Public

  public override func run(in context: ASTContext) {
    var topLevel = [Expr]()
    topLevel.append(contentsOf: context.globals as [Expr])
    topLevel.append(contentsOf: context.types as [Expr])
    topLevel.append(contentsOf: context.functions as [Expr])
    topLevel.append(contentsOf: context.typeAliases as [Expr])
    topLevel.append(contentsOf: context.extensions as [Expr])

    topLevel.sort { e1, e2 in
      // foreign and implicit decls show up first
      guard let e1Loc = e1.startLoc(),
            let e2Loc = e2.startLoc()
      else { return true }
      return e1Loc < e2Loc
    }
    for e in topLevel {
      visit(e)
      stream.write("\n\n")
    }
  }

  public override func visitNumExpr(_ expr: NumExpr) {
    stream.write("\(expr.raw)")
  }

  public override func visitCharExpr(_ expr: CharExpr) {
    stream.write("'\(Character(UnicodeScalar(expr.value)))'")
  }

  public override func visitVarExpr(_ expr: VarExpr) {
    stream.write("\(expr.name)")
  }

  public override func visitVoidExpr(_ expr: VoidExpr) {
    stream.write("")
  }

  public override func visitBoolExpr(_ expr: BoolExpr) {
    stream.write("\(expr.value)")
  }

  public override func visitVarAssignExpr(_ expr: VarAssignExpr) {
    for attr in expr.attributes {
      stream.write(attr.rawValue + " ")
    }
    let tok = expr.isMutable ? "mut" : "let"
    stream.write("\(tok) \(expr.name)")
    if let type = expr.typeRef?.type {
      stream.write(": \(type)")
    }
    if let rhs = expr.rhs {
      stream.write(" = ")
      visit(rhs)
    }
  }

  public override func visitFuncArgumentAssignExpr(_ expr: FuncArgumentAssignExpr) {
    if let externalName = expr.externalName {
      stream.write(externalName.name)
    } else {
      stream.write("_")
    }

    if !expr.name.name.isEmpty && expr.name != expr.externalName {
      stream.write(" " + expr.name.name)
    }

    if let type = expr.typeRef {
      stream.write(": " + type.name.name)
    }
  }

  public override func visitTypeAliasExpr(_ expr: TypeAliasExpr) {
    stream.write("type \(expr.name) = ")
    visit(expr.bound)
  }

  public override func visitNilExpr(_ expr: NilExpr) {
    stream.write("nil")
  }

  public override func visitSizeofExpr(_ expr: SizeofExpr) {
    stream.write("sizeof(")
    _ = expr.value.map(visit)
    stream.write(")")
  }

  public override func visitFuncDeclExpr(_ expr: FuncDeclExpr) {
    for attr in expr.attributes {
      stream.write(attr.rawValue + " ")
    }

    if expr.isInitializer {
      stream.write("init")
    } else {
      stream.write("fn \(expr.name)")
    }
    writeSignature(
      args: expr.args,
      ret: expr.returnType,
      hasVarArgs: expr.hasVarArgs
    )
    stream.write(" ")
    if let body = expr.body {
      visitCompoundExpr(body)
    }
  }

  public override func visitClosureExpr(_ expr: ClosureExpr) {
    stream.write("{")
    writeSignature(args: expr.args, ret: expr.returnType, hasVarArgs: false)
    stream.write(" in\n")
    withIndent {
      for e in expr.body.exprs {
        writeIndent()
        visit(e)
        stream.write("\n")
      }
    }
    stream.write("}")
  }

  public override func visitReturnExpr(_ expr: ReturnExpr) {
    stream.write("return ")
    visit(expr.value)
  }

  public override func visitBreakExpr(_ expr: BreakExpr) {
    stream.write("break")
  }

  public override func visitContinueExpr(_ expr: ContinueExpr) {
    stream.write("continue")
  }

  public override func visitStringExpr(_ expr: StringExpr) {
    stream.write("\"\(expr.value.escaped())\"")
  }

  public override func visitSubscriptExpr(_ expr: SubscriptExpr) {
    visit(expr.lhs)
    stream.write("[")
    visit(expr.amount)
    stream.write("]")
  }

  public override func visitTupleExpr(_ expr: TupleExpr) {
    stream.write("(")
    for (idx, value) in expr.values.enumerated() {
      visit(value)
      if idx != expr.values.endIndex - 1 {
        stream.write(", ")
      }
    }
    stream.write(")")
  }

  public override func visitTupleFieldLookupExpr(_ expr: TupleFieldLookupExpr) {
    visit(expr.lhs)
    stream.write(".\(expr.field)")
  }

  public override func visitPoundFunctionExpr(_ expr: PoundFunctionExpr) {
    stream.write("#function")
  }

  public override func visitPoundDiagnosticExpr(_ expr: PoundDiagnosticExpr) {
    stream.write("#\(expr.isError ? "error" : "warning") ")
    visit(expr.content)
  }

  public override func visitTypeRefExpr(_ expr: TypeRefExpr) {
    stream.write("\(expr.name)")
  }

  public override func visitFloatExpr(_ expr: FloatExpr) {
    stream.write("\(expr.value)")
  }

  public override func visitCompoundExpr(_ expr: CompoundExpr) {
    visitCompoundExpr(expr, braced: true)
  }

  public override func visitFuncCallExpr(_ expr: FuncCallExpr) {
    visit(expr.lhs)
    stream.write("(")
    for (idx, arg) in expr.args.enumerated() {
      if let label = arg.label {
        stream.write(label.name + ": ")
      }
      visit(arg.val)
      if idx != expr.args.count - 1 {
        stream.write(", ")
      }
    }
    stream.write(")")
  }

  public override func visitTypeDeclExpr(_ expr: TypeDeclExpr) {
    for attr in expr.attributes {
      stream.write(attr.rawValue + " ")
    }

    stream.write("type \(expr.name) {")
    if expr.fields.count + expr.methods.count == 0 {
      stream.write("{")
      return
    }
    stream.write("\n")
    withIndent {
      for field in expr.fields {
        writeIndent()
        visitVarAssignExpr(field)
        stream.write("\n")
      }

      for method in expr.methods {
        writeIndent()
        visitFuncDeclExpr(method)
        stream.write("\n")
      }
    }
    stream.write("}")
  }

  public override func visitExtensionExpr(_ expr: ExtensionExpr) {
    stream.write("extension ")
    visit(expr.typeRef)
    stream.write(" {\n")
    withIndent {
      for method in expr.methods {
        writeIndent()
        visitFuncDeclExpr(method)
        stream.write("\n")
      }
    }
    stream.write("}")
  }

  public override func visitWhileExpr(_ expr: WhileExpr) {
    stream.write("while ")
    visit(expr.condition)
    stream.write(" ")
    visitCompoundExpr(expr.body)
  }

  public override func visitForLoopExpr(_ expr: ForLoopExpr) {
    stream.write("for ")
    if let initial = expr.initializer {
      visit(initial)
    }

    stream.write("; ")
    if let cond = expr.condition {
      visit(cond)
    }
    stream.write("; ")
    if let incr = expr.incrementer {
      visit(incr)
    }
    stream.write("; ")
    visitCompoundExpr(expr.body)
  }

  public override func visitIfExpr(_ expr: IfExpr) {
    var hasPrintedInitial = false
    for (cond, body) in expr.blocks {
      if hasPrintedInitial {
        stream.write(" else ")
      }
      hasPrintedInitial = true
      stream.write("if ")
      visit(cond)
      stream.write(" ")
      visitCompoundExpr(body)
    }
    if let `else` = expr.elseBody {
      stream.write(" else ")
      visitCompoundExpr(`else`)
    }
  }

  public override func visitTernaryExpr(_ expr: TernaryExpr) {
    visit(expr.condition)
    stream.write(" ? ")
    visit(expr.trueCase)
    stream.write(" : ")
    visit(expr.falseCase)
  }

  public override func visitSwitchExpr(_ expr: SwitchExpr) {
    stream.write("switch ")
    visit(expr.value)
    stream.write(" {\n")
    for c in expr.cases {
      writeIndent()
      visitCaseExpr(c)
    }
    if let def = expr.defaultBody {
      writeIndent()
      stream.write("default:")
      visitCompoundExpr(def, braced: false)
    }
    writeIndent()
    stream.write("}")
  }

  public override func visitCaseExpr(_ expr: CaseExpr) {
    stream.write("case ")
    visit(expr.constant)
    stream.write(":")
    visitCompoundExpr(expr.body, braced: false)
  }

  public override func visitInfixOperatorExpr(_ expr: InfixOperatorExpr) {
    visit(expr.lhs)
    stream.write(" \(expr.op) ")
    visit(expr.rhs)
  }

  public override func visitPrefixOperatorExpr(_ expr: PrefixOperatorExpr) {
    stream.write("\(expr.op)")
    visit(expr.rhs)
  }

  public override func visitFieldLookupExpr(_ expr: FieldLookupExpr) {
    visit(expr.lhs)
    stream.write(".")
    stream.write(expr.name.name)
  }

  public override func visitParenExpr(_ expr: ParenExpr) {
    stream.write("(")
    visit(expr.value)
    stream.write(")")
  }

  // MARK: Internal

  var stream: StreamType
  var indentLevel: Int = 0

  func withIndent(_ f: () -> Void) {
    indent()
    f()
    dedent()
  }

  // MARK: Private

  private func indent() {
    indentLevel += 2
  }

  private func dedent() {
    indentLevel -= 2
  }

  private func writeIndent() {
    stream.write(String(repeating: " ", count: indentLevel))
  }

  private func writeSignature(
    args: [FuncArgumentAssignExpr],
    ret: TypeRefExpr,
    hasVarArgs: Bool
  ) {
    stream.write("(")
    for (idx, arg) in args.enumerated() {
      visitFuncArgumentAssignExpr(arg)
      if idx != args.count - 1 || hasVarArgs {
        stream.write(", ")
      }
    }
    if hasVarArgs {
      stream.write("_: ...")
    }
    stream.write(")")
    if ret != .void {
      stream.write(" -> ")
      visit(ret)
    }
  }

  private func visitCompoundExpr(_ expr: CompoundExpr, braced: Bool) {
    if braced {
      stream.write("{")
    }
    stream.write("\n")
    withIndent {
      for e in expr.exprs {
        writeIndent()
        visit(e)
        stream.write("\n")
      }
    }
    if braced {
      writeIndent()
      stream.write("}")
    }
  }

}
