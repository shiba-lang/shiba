//
//  TypeChecker.swift
//  Shiba
//
//  Created by Khoa Le on 02/12/2020.
//

import Foundation

// MARK: - TypeCheckError

fileprivate enum TypeCheckError: Error, CustomStringConvertible {
  case incorrectArgumentLabel(got: Identifier, expected: Identifier)
  case missingArgumentLabel(expected: Identifier)
  case extraArgumentLabel(got: Identifier)
  case arityMismatch(name: Identifier, gotCount: Int, expectedCount: Int)
  case invalidBinOpArgs(op: BuiltinOperator, lhs: DataType, rhs: DataType)
  case typeMismatch(expected: DataType, got: DataType)
  case nonBooleanTernary(got: DataType)
  case nonBoolCondition(got: DataType?)
  case overflow(raw: String, type: DataType)
  case subscriptWithInvalidType(type: DataType)

  // MARK: Internal

  var description: String {
    switch self {
    case let .incorrectArgumentLabel(got, expected):
      return "incorrect argument label (expected '\(expected)', got '\(got)')"
    case let .missingArgumentLabel(expected):
      return "missing argument label (expected '\(expected)')"
    case let .extraArgumentLabel(got):
      return "extra argument label (got '\(got)')"
    case let .arityMismatch(name, gotCount, expectedCount):
      return "expected \(expectedCount) arguments to function \(name) (got \(gotCount)"
    case let .invalidBinOpArgs(op, lhs, rhs):
      return "cannot apply binary operator '\(op)' to operands of type '\(lhs)' and '\(rhs)'"
    case let .typeMismatch(expected, got):
      return "type mismatch (expected value of type '\(expected)', got '\(got)')"
    case let .nonBooleanTernary(got):
      return "ternary condition must be a Bool (got '\(got)')"
    case let .nonBoolCondition(got):
      let typeName = got != nil ? "\(got!)" : "<<error type>>"
      return "if condition must be a Bool (got '\(typeName)')"
    case let .overflow(raw, type):
      return "value '\(raw)' overflows when stored into '\(type)'"
    case let .subscriptWithInvalidType(type):
      return "cannot subscript witch argument of type \(type)"
    }
  }
}

// MARK: - TypeChecker

public class TypeChecker: ASTTransformer, Pass {
  public var title: String {
    "Type Checking"
  }

  public func ensureTypesAndLabelsMatch(_ expr: FuncCallExpr, decl: FuncDeclExpr) {
    let precondition: Bool
    var declArgs = decl.args

    if let first = declArgs.first, first.isImplicitSelf {
      declArgs.removeFirst()
    }

    if decl.hasVarArgs {
      precondition = declArgs.count <= expr.args.count
    } else {
      precondition = declArgs.count == expr.args.count
    }

    if !precondition {
      let name = Identifier(name: "\(expr)")
      error(TypeCheckError.arityMismatch(
        name: name,
        gotCount: expr.args.count,
        expectedCount: declArgs.count
      ))
      return
    }

    for (arg, val) in zip(declArgs, expr.args) {
      if let externalName = arg.externalName {
        guard let label = val.label else {
          error(
            TypeCheckError.missingArgumentLabel(expected: externalName),
            loc: val.val.startLoc()
          )
          continue
        }
        if label.name != externalName.name {
          error(
            TypeCheckError.incorrectArgumentLabel(
              got: label,
              expected: externalName
            ),
            loc: val.val.startLoc(),
            highlights: [val.val.sourceRange]
          )
        }
      } else if let label = val.label {
        error(
          TypeCheckError.extraArgumentLabel(got: label),
          loc: val.val.startLoc()
        )
      }
      var argType = arg.type
      guard let type = val.val.type else {
        // TODO: - Better error handling
        fatalError("unable to resolve val type")
      }
      if arg.isImplicitSelf {
        argType = argType.rootType
      }

      if !matches(argType, .any) && !matches(type, argType) {
        error(
          TypeCheckError.typeMismatch(expected: argType, got: type),
          loc: val.val.startLoc(),
          highlights: [val.val.sourceRange]
        )
      }
    }
  }

  public override func visitNumExpr(_ expr: NumExpr) {
    guard let type = expr.type else { return }
    let canTy = context.canonicalType(type)
    guard case .int(let width, _) = canTy else {
      fatalError("non-number expr?")
    }
    var overflows = false
    switch width {
    case 8:
      if expr.value > Int64(Int8.max) { overflows = true }
    case 16:
      if expr.value > Int64(Int16.max) { overflows = true }
    case 32:
      if expr.value > Int64(Int32.max) { overflows = true }
    case 64:
      if expr.value > Int64(Int64.max) { overflows = true }
    default: break
    }
    if overflows {
      let err = TypeCheckError.overflow(raw: expr.raw, type: expr.type!)
      error(err, loc: expr.startLoc(), highlights: [expr.sourceRange])
      return
    }
  }

  public override func visitSwitchExpr(_ expr: SwitchExpr) {
    for c in expr.cases where !matches(c.constant.type, expr.value.type) {
      error(
        TypeCheckError.typeMismatch(
          expected: expr.value.type!,
          got: c.constant.type!
        ),
        loc: c.constant.startLoc(),
        highlights: [c.constant.sourceRange!]
      )
    }
  }

  public override func visitVarExpr(_ expr: VarExpr) {
    guard let decl = expr.decl,
          let type = expr.type else { return }
    if !matches(decl.type, type) {
      error(
        TypeCheckError.typeMismatch(expected: decl.type, got: type),
        loc: expr.startLoc()
      )
    }
    super.visitVarExpr(expr)
  }

  public override func visitVarAssignExpr(_ expr: VarAssignExpr) {
    if let rhs = expr.rhs {
      guard let rhsType = rhs.type else { return }
      if !matches(expr.type, rhsType) {
        error(
          TypeCheckError.typeMismatch(expected: expr.type, got: rhsType),
          loc: expr.startLoc()
        )
        return
      }
    }
    super.visitVarAssignExpr(expr)
  }

  public override func visitIfExpr(_ expr: IfExpr) {
    for (expr, _) in expr.blocks {
      guard case .bool? = expr.type else {
        error(
          TypeCheckError.nonBoolCondition(got: expr.type),
          loc: expr.startLoc(),
          highlights: [expr.sourceRange]
        )
        return
      }
    }
    super.visitIfExpr(expr)
  }

  public override func visitFuncArgumentAssignExpr(_ expr: FuncArgumentAssignExpr) {
    if let rhsType = expr.rhs?.type, !matches(expr.type, rhsType) {
      error(
        TypeCheckError.typeMismatch(expected: expr.type, got: rhsType),
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
    }
    super.visitFuncArgumentAssignExpr(expr)
  }

  public override func visitReturnExpr(_ expr: ReturnExpr) {
    guard let returnType = currentClosure?.returnType.type ?? currentFunction?.returnType.type,
          let valType = expr.value.type else { return }
    if !matches(valType, returnType) {
      error(
        TypeCheckError.typeMismatch(expected: returnType, got: valType),
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
    }
    super.visitReturnExpr(expr)
  }

  public override func visitFuncCallExpr(_ expr: FuncCallExpr) {
    guard let decl = expr.decl else { return }
    ensureTypesAndLabelsMatch(expr, decl: decl)
    super.visitFuncCallExpr(expr)
  }

  public override func visitTernaryExpr(_ expr: TernaryExpr) {
    guard let condType = expr.condition.type,
          let trueType = expr.trueCase.type,
          let falseType = expr.falseCase.type else { return }
    guard matches(condType, .bool) else {
      error(
        TypeCheckError.nonBooleanTernary(got: condType),
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
      return
    }

    guard matches(trueType, falseType) else {
      error(
        TypeCheckError.typeMismatch(expected: trueType, got: falseType),
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
      return
    }
    super.visitTernaryExpr(expr)
  }

  public override func visitInfixOperatorExpr(_ expr: InfixOperatorExpr) {
    guard let lhsType = expr.lhs.type,
          let rhsType = expr.rhs.type else { return }
    if expr.op == .as {
      // thrown from sema
    } else if expr.type(forArgType: lhsType) == nil {
      error(
        TypeCheckError.invalidBinOpArgs(op: expr.op, lhs: lhsType, rhs: rhsType),
        loc: expr.startLoc(),
        highlights: [expr.lhs.sourceRange]
      )
    } else if !matches(lhsType, rhsType) {
      error(TypeCheckError.invalidBinOpArgs(
        op: expr.op,
        lhs: lhsType,
        rhs: rhsType
      ), loc: expr.opRange?.start, highlights: [
        expr.lhs.sourceRange,
        expr.opRange,
        expr.rhs.sourceRange,
      ])
    }
    super.visitInfixOperatorExpr(expr)
  }

  public override func visitSubscriptExpr(_ expr: SubscriptExpr) {
    guard let amountType = expr.amount.type else { return }
    guard case .int = context.canonicalType(amountType) else {
      error(
        TypeCheckError.subscriptWithInvalidType(type: amountType),
        loc: expr.amount.startLoc(),
        highlights: [expr.amount.sourceRange, expr.lhs.sourceRange]
      )
      return
    }
  }
}
