//
//  ASTDumper.swift
//  Shiba
//
//  Created by Khoa Le on 04/12/2020.
//

import Foundation

public final class ASTDumper<StreamType: TextOutputStream>: ASTTransformer {

  // MARK: Lifecycle

  public init(stream: inout StreamType, context: ASTContext) {
    self.stream = stream
    super.init(context: context)
  }

  required public init(context: ASTContext) {
    fatalError("init(context:) has not been implemented")
  }

  // MARK: Public

  public typealias Result = Void

  public override func visitNumExpr(_ expr: NumExpr) {
    printExpr("NumExpr \(expr.value)", expr.startLoc())
  }

  public override func visitCharExpr(_ expr: CharExpr) {
    let v = Character(UnicodeScalar(expr.value))
    printExpr("CharExpr \(v)", expr.startLoc())
  }

  public override func visitVarExpr(_ expr: VarExpr) {
    printExpr("VarExpr \(expr.name)", expr.startLoc())
  }

  public override func visitVoidExpr(_ expr: VoidExpr) {
    printExpr("VoidExpr", expr.startLoc())
  }

  public override func visitBoolExpr(_ expr: BoolExpr) {
    printExpr("BoolExpr \(expr.value)", expr.startLoc())
  }

  public override func visitVarAssignExpr(_ expr: VarAssignExpr) {
    var s = "VarAssignExpr \(expr.name)"
    if let type = expr.typeRef?.type {
      s += ": \(type)"
    }

    printExpr(s, expr.startLoc()) {
      super.visitVarAssignExpr(expr)
    }
  }

  public override func visitFuncArgumentAssignExpr(_ expr: FuncArgumentAssignExpr) -> Result {
    var s = "FuncArgumentAssignExpr "
    if let externalName = expr.externalName {
      s += externalName.name + " "
    }
    s += expr.name.name + " "
    if let type = expr.typeRef {
      s += type.name.name
    }
    printExpr(s, expr.startLoc()) {
      super.visitFuncArgumentAssignExpr(expr)
    }
  }

  public override func visitTypeAliasExpr(_ expr: TypeAliasExpr) -> Result {
    printExpr("TypeAliasExpr \(expr.name) \(expr.bound.name)", expr.startLoc())
  }

  public override func visitFuncDeclExpr(_ expr: FuncDeclExpr) -> Result {
    if expr.has(attribute: .foreign) {
      return
    }
    printExpr(
      "FuncDeclExpr \(expr.name) \(expr.returnType.name)",
      expr.startLoc()
    ) {
      super.visitFuncDeclExpr(expr)
    }
  }

  public override func visitClosureExpr(_ expr: ClosureExpr) -> Result {
    let retName = expr.returnType.name
    printExpr("ClosureExpr \(retName)", expr.startLoc()) {
      super.visitClosureExpr(expr)
    }
  }

  public override func visitReturnExpr(_ expr: ReturnExpr) -> Result {
    printExpr("ReturnExpr", expr.startLoc()) {
      super.visitReturnExpr(expr)
    }
  }

  public override func visitBreakExpr(_ expr: BreakExpr) {
    printExpr("BreakExpr", expr.startLoc())
  }

  public override func visitContinueExpr(_ expr: ContinueExpr) -> Result {
    printExpr("ContinueExpr", expr.startLoc())
  }

  public override func visitStringExpr(_ expr: StringExpr) {
    printExpr("StringExpr \"\(expr.value.escaped())\"", expr.startLoc())
  }

  public override func visitSubscriptExpr(_ expr: SubscriptExpr) {
    printExpr("SubscriptExpr", expr.startLoc()) {
      super.visitSubscriptExpr(expr)
    }
  }

  public override func visitTypeRefExpr(_ expr: TypeRefExpr) {
    printExpr("TypeRefExpr \"\(expr.name)\"", expr.startLoc()) {
      super.visitTypeRefExpr(expr)
    }
  }

  public override func visitFloatExpr(_ expr: FloatExpr) {
    printExpr("FloatExpr \(expr.value)", expr.startLoc())
  }


  public override func visitCompoundExpr(_ expr: CompoundExpr) -> Result {
    printExpr("CompoundExpr", expr.startLoc()) {
      super.visitCompoundExpr(expr)
    }
  }

  public override func visitFuncCallExpr(_ expr: FuncCallExpr) -> Result {
    printExpr("FuncCallExpr", expr.startLoc()) {
      super.visitFuncCallExpr(expr)
    }
  }

  public override func visitTypeDeclExpr(_ expr: TypeDeclExpr) -> Result {
    if expr.has(attribute: .foreign) { return }
    printExpr("TypeDeclExpr \(expr.name)", expr.startLoc()) {
      super.visitTypeDeclExpr(expr)
    }
  }

  public override func visitExtensionExpr(_ expr: ExtensionExpr) -> Result {
    printExpr("ExtensionExpr \(expr.type!)", expr.startLoc()) {
      super.visitExtensionExpr(expr)
    }
  }

  public override func visitWhileExpr(_ expr: WhileExpr) -> Result {
    printExpr("WhileExpr", expr.startLoc()) {
      super.visitWhileExpr(expr)
    }
  }

  public override func visitForLoopExpr(_ expr: ForLoopExpr) -> Result {
    printExpr("ForLoopExpr", expr.startLoc()) {
      super.visitForLoopExpr(expr)
    }
  }

  public override func visitIfExpr(_ expr: IfExpr) -> Result {
    printExpr("IfExpr", expr.startLoc()) {
      super.visitIfExpr(expr)
    }
  }

  public override func visitTernaryExpr(_ expr: TernaryExpr) -> Result {
    printExpr("TernaryExpr", expr.startLoc()) {
      super.visitTernaryExpr(expr)
    }
  }

  public override func visitSwitchExpr(_ expr: SwitchExpr) -> Result {
    printExpr("SwitchExpr", expr.startLoc()) {
      super.visitSwitchExpr(expr)
    }
  }

  public override func visitCaseExpr(_ expr: CaseExpr) -> Result {
    printExpr("CaseExpr", expr.startLoc()) {
      super.visitCaseExpr(expr)
    }
  }

  public override func visitInfixOperatorExpr(_ expr: InfixOperatorExpr) -> Result {
    printExpr("InfixOperatorExpr \(expr.op)", expr.startLoc()) {
      super.visitInfixOperatorExpr(expr)
    }
  }

  public override func visitPrefixOperatorExpr(_ expr: PrefixOperatorExpr) -> Result {
    printExpr("PrefixOperatorExpr \(expr.op)", expr.startLoc()) {
      super.visitPrefixOperatorExpr(expr)
    }
  }

  public override func visitFieldLookupExpr(_ expr: FieldLookupExpr) -> Result {
    printExpr("FieldLookupExpr \(expr.name)", expr.startLoc()) {
      super.visitFieldLookupExpr(expr)
    }
  }

  public override func visitTupleExpr(_ expr: TupleExpr) {
    printExpr("TupleExpr", expr.startLoc()) {
      super.visitTupleExpr(expr)
    }
  }

  public override func visitTupleFieldLookupExpr(_ expr: TupleFieldLookupExpr) {
    printExpr("TupleFieldLookupExpr \(expr.field)", expr.startLoc()) {
      super.visitTupleFieldLookupExpr(expr)
    }
  }

  public override func visitParenExpr(_ expr: ParenExpr) -> Result {
    printExpr("ParenExpr", expr.startLoc()) {
      super.visitParenExpr(expr)
    }
  }

  public override func visitPoundDiagnosticExpr(_ expr: PoundDiagnosticExpr) -> () {
    printExpr(
      "PoundDiagnostic \(expr.isError ? "error" : "warning")",
      expr.startLoc()
    ) {
      super.visitPoundDiagnosticExpr(expr)
    }
  }

  // MARK: Internal

  var indentLevel = 0

  var stream: StreamType

  // MARK: Private

  private func printExpr(
    _ description: String,
    _ loc: SourceLocation?, then: (() -> Void)? = nil
  ) {
    stream.write(String(repeating: " ", count: indentLevel))
    stream.write("\(description) \(loc?.description ?? "<unknown>")\n")
    if let then = then {
      indent()
      then()
      dedent()
    }
  }

  private func indent() {
    indentLevel += 2
  }

  private func dedent() {
    indentLevel -= 2
  }

}
