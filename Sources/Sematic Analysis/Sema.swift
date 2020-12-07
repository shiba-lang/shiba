//
//  Sema.swift
//  Shiba
//
//  Created by Khoa Le on 02/12/2020.
//

import Foundation

// MARK: - SemaError

fileprivate enum SemaError: Error, CustomStringConvertible {
  case unknownFunction(name: Identifier)
  case unknownType(type: DataType)
  case callNonFunction(type: DataType?)
  case unknownField(typeDecl: TypeDeclExpr, expr: FieldLookupExpr)
  case unknownVariableName(name: Identifier)
  case invalidOperands(op: BuiltinOperator, invalid: DataType)
  case cannotSubscript(type: DataType)
  case cannotCoerce(type: DataType, toType: DataType)
  case varArgsInNonForeignDecl
  case foreignFunctionWithBody(name: Identifier)
  case nonForeignFunctionWithoutBody(name: Identifier)
  case foreignVarWithRHS(name: Identifier)
  case dereferenceNonPointer(type: DataType)
  case cannotSwitch(type: DataType)
  case nonPointerNil(type: DataType)
  case notAllPathsReturn(type: DataType)
  case noViableOverload(name: Identifier, args: [Argument])
  case ambiguousReference(name: Identifier)
  case addressOfRValue
  case breakNotAllowed
  case continueNotAllowed
  case fieldOfFunctionType(type: DataType)
  case duplicateMethod(name: Identifier, type: DataType)
  case duplicateField(name: Identifier, type: DataType)
  case referenceSelfInProp(name: Identifier)
  case poundFunctionOutsideFunction
  case assignToConstant(name: Identifier?)
  case deinitOnStruct(name: Identifier?)
  case indexIntoNonTuple
  case outOfBoundsTupleField(field: Int, max: Int)

  // MARK: Internal

  var description: String {
    switch self {
    case let .unknownFunction(name):
      return "unknown function '\(name)'"
    case let .unknownType(type):
      return "unknown type '\(type)'"
    case let .callNonFunction(type):
      let t = type.map { String(describing: $0) } ?? "<<error type>>"
      return "cannot call non-function type '\(t)'"
    case let .unknownField(typeDecl, expr):
      return "unknown field name '\(expr.name)' in type '\(typeDecl)'"
    case let .unknownVariableName(name):
      return "unknown variable '\(name)'"
    case let .invalidOperands(op, invalid):
      return "invalid argument for operator '\(op)' (got '\(invalid)')"
    case let .cannotSubscript(type):
      return "cannot subscript value of type '\(type)'"
    case let .cannotCoerce(type, toType):
      return "cannot coerce '\(type)' to '\(toType)'"
    case .varArgsInNonForeignDecl:
      return "varargs in non-foreign declarations are not yet supported"
    case let .foreignFunctionWithBody(name):
      return "foreign function '\(name)' cannot have a body"
    case let .nonForeignFunctionWithoutBody(name):
      return "function '\(name) must have a body"
    case let .foreignVarWithRHS(name):
      return "foreign var '\(name)' cannot have a value"
    case let .dereferenceNonPointer(type):
      return "cannot dereference a value of non-pointer type '\(type)'"
    case let .cannotSwitch(type):
      return "cannot switch over values of type '\(type)'"
    case let .nonPointerNil(type):
      return "cannot set non-pointer type '\(type)' to nil"
    case let .notAllPathsReturn(type):
      return "missing return in a function expected to return \(type)"
    case let .noViableOverload(name, args):
      var s = "could not find a viable overload for \(name) with arguments of type ("
      s += args.map {
        var d = ""
        if let label = $0.label {
          d += "\(label): "
        }
        if let t = $0.val.type {
          d += "\(t)"
        } else {
          d += "<<error type>>"
        }
        return d
      }.joined(separator: ", ")
      s += ")"
      return s
    case let .ambiguousReference(name):
      return "ambiguous reference to '\(name)'"
    case .addressOfRValue:
      return "cannot get address of an r-value"
    case .breakNotAllowed:
      return "'break' not allowed outside loop"
    case .continueNotAllowed:
      return "'continue' not allowed outside loop"
    case let .fieldOfFunctionType(type):
      return "cannot fiend field on function of type \(type)"
    case let .duplicateMethod(name, type):
      return "invalid redeclaration of method '\(name)' on type '\(type)'"
    case let .duplicateField(name, type):
      return "invalid redeclaration of field '\(name)' on type '\(type)'"
    case let .referenceSelfInProp(name):
      return "type '\(name)' cannot have a property that reference itself"
    case .poundFunctionOutsideFunction:
      return "'#funtion' is only valid inside function scope"
    case let .assignToConstant(name):
      let v: String
      if let n = name {
        v = "'\(n)'"
      } else {
        v = "expression"
      }
      return "cannot mutate \(v); expression is a 'let' constant"
    case let .deinitOnStruct(name):
      return "cannot have a deinitializer in non-indirect type '\(name ?? "<<error type>>")'"
    case .indexIntoNonTuple:
      return "cannot index into non-tuple expression"
    case let .outOfBoundsTupleField(field, max):
      return "cannot access field \(field) in tuple with \(max) fields"
    }
  }
}

// MARK: - Sema

public class Sema: ASTTransformer, Pass {

  // MARK: Public

  public var title: String {
    "Semantic Analysis"
  }

  public override func run(in context: ASTContext) {
    registerTopLevelDecls(in: context)
    super.run(in: context)
  }

  public override func visitFuncDeclExpr(_ expr: FuncDeclExpr) {
    super.visitFuncDeclExpr(expr)

    if expr.has(attribute: .foreign) {
      error(
        SemaError.foreignFunctionWithBody(name: expr.name),
        loc: expr.name.range?.start,
        highlights: [expr.name.range]
      )
      return
    } else {
      if !expr.has(attribute: .implicit) && expr.body == nil {
        error(
          SemaError.nonForeignFunctionWithoutBody(name: expr.name),
          loc: expr.name.range?.start,
          highlights: [expr.name.range]
        )
        return
      }

      if expr.hasVarArgs {
        error(SemaError.varArgsInNonForeignDecl, loc: expr.startLoc())
        return
      }
    }
    guard let returnType = expr.returnType.type else { return }
    if !context.isValidType(returnType) {
      error(
        SemaError.unknownType(type: returnType),
        loc: expr.returnType.startLoc(),
        highlights: [expr.returnType.sourceRange]
      )
      return
    }
    if let body = expr.body,
       !body.hasReturn,
       returnType != .void,
       !expr.isInitializer
    {
      error(
        SemaError.notAllPathsReturn(type: returnType),
        loc: expr.name.range?.start,
        highlights: [expr.name.range, expr.returnType.sourceRange]
      )
      return
    }
    if case .deinitializer(let type) = expr.kind,
       let decl = context.decl(for: type, canonicalized: true),
       !decl.isIndirect
    {
      error(SemaError.deinitOnStruct(name: decl.name))
    }
  }

  public override func withScope(_ e: CompoundExpr, _ f: () -> Void) {
    let oldVarBindings = varBindings
    super.withScope(e, f)
    varBindings = oldVarBindings
  }

  public override func visitVarAssignExpr(_ expr: VarAssignExpr) {
    super.visitVarAssignExpr(expr)
    if let rhs = expr.rhs, expr.has(attribute: .foreign) {
      error(
        SemaError.foreignVarWithRHS(name: expr.name),
        loc: expr.startLoc(),
        highlights: [rhs.sourceRange]
      )
      return
    }
    guard !expr.has(attribute: .foreign) else { return }
    if let type = expr.typeRef?.type {
      if !context.isValidType(type) {
        error(
          SemaError.unknownType(type: type),
          loc: expr.typeRef!.startLoc(),
          highlights: [expr.typeRef!.sourceRange]
        )
        return
      }

      if let rhs = expr.rhs, let rhsType = rhs.type {
        if context.canCoerce(rhsType, to: type) {
          rhs.type = type
        }
      }
    }
    if expr.containingTypeDecl == nil {
      varBindings[expr.name.name] = expr
    }
    if let rhs = expr.rhs, expr.typeRef == nil {
      guard let type = rhs.type else { return }
      expr.type = type
      expr.typeRef = type.ref()
    }
  }

  public override func visitParenExpr(_ expr: ParenExpr) {
    super.visitParenExpr(expr)
    expr.type = expr.value.type
  }

  public override func visitSizeofExpr(_ expr: SizeofExpr) {
    let handleVar = { (varExpr: VarExpr) in
      let possibleType = DataType(name: varExpr.name.name)
      if self.context.isValidType(possibleType) {
        expr.valueType = possibleType
      } else {
        super.visitSizeofExpr(expr)
        expr.valueType = varExpr.type
      }
    }
    if let varExpr = expr.value as? VarExpr {
      handleVar(varExpr)
    } else if let varExpr = (expr.value as? ParenExpr)?.rootExpr as? VarExpr {
      handleVar(varExpr)
    } else {
      super.visitSizeofExpr(expr)
      expr.valueType = expr.value?.type
    }
  }

  public override func visitFuncArgumentAssignExpr(_ expr: FuncArgumentAssignExpr) {
    super.visitFuncArgumentAssignExpr(expr)
    guard context.isValidType(expr.type) else {
      error(
        SemaError.unknownType(type: expr.type),
        loc: expr.typeRef?.startLoc(),
        highlights: [expr.typeRef?.sourceRange]
      )
      return
    }
    let canonTy = context.canonicalType(expr.type)
    if case .custom = canonTy,
       context.decl(for: canonTy)!.isIndirect
    {
      expr.isMutable = true
    }
    varBindings[expr.name.name] = expr
  }

  public override func visitFieldLookupExpr(_ expr: FieldLookupExpr) {
    _ = visitFieldLookupExpr(expr, callArgs: nil)
  }

  /// - returns: true if the resulting is a field of fuonction type,
  ///							instead of a method
  public func visitFieldLookupExpr(
    _ expr: FieldLookupExpr,
    callArgs: [Argument]?
  ) -> Bool {
    super.visitFieldLookupExpr(expr)
    guard let type = expr.lhs.type else {
      // An error will already have been thrown from here
      return false
    }
    if case .function = type {
      error(
        SemaError.fieldOfFunctionType(type: type),
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
      return false
    }
    guard let typeDecl = context.decl(for: type) else {
      error(
        SemaError.unknownType(type: type.rootType),
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
      return false
    }
    expr.typeDecl = typeDecl
    let candidateMethods = typeDecl.methods(named: expr.name.name)
    if let callArgs = callArgs,
       let index = typeDecl.indexOf(fieldName: expr.name)
    {
      let field = typeDecl.fields[index]
      if case .function(let args, _) = field.type {
        let types = callArgs.compactMap { $0.val.type }
        if types.count == callArgs.count && args == types {
          expr.decl = field
          expr.type = field.type
          return true
        }
      }
    }
    if let decl = typeDecl.field(named: expr.name.name) {
      expr.decl = decl
      expr.type = decl.type
      return true
    } else if !candidateMethods.isEmpty {
      if let args = callArgs,
         let funcDecl = candidate(forArgs: args, candidates: candidateMethods)
      {
        expr.decl = funcDecl
        let types = funcDecl.args.map { $0.type }
        expr.type = .function(args: types, returnType: funcDecl.returnType.type!)
        return false
      } else {
        error(
          SemaError.ambiguousReference(name: expr.name),
          loc: expr.startLoc(),
          highlights: [expr.sourceRange]
        )
        return false
      }
    } else {
      error(
        SemaError.unknownField(typeDecl: typeDecl, expr: expr),
        loc: expr.startLoc(),
        highlights: [expr.name.range]
      )
      return false
    }
  }

  public override func visitTupleFieldLookupExpr(_ expr: TupleFieldLookupExpr) {
    super.visitTupleFieldLookupExpr(expr)
    guard let lhsTy = expr.lhs.type else { return }
    let lhsCanTy = context.canonicalType(lhsTy)
    guard case .tuple(let fields) = lhsCanTy else {
      error(
        SemaError.indexIntoNonTuple,
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
      return
    }
    if expr.field >= fields.count {
      error(
        SemaError.outOfBoundsTupleField(field: expr.field, max: fields.count),
        loc: expr.fieldRange.start,
        highlights: [expr.fieldRange]
      )
    }
  }

  public override func visitSubscriptExpr(_ expr: SubscriptExpr) {
    super.visitSubscriptExpr(expr)
    guard let type = expr.lhs.type else { return }
    guard case .pointer(let subtype) = type else {
      error(
        SemaError.cannotSubscript(type: type),
        loc: expr.startLoc(),
        highlights: [expr.lhs.sourceRange]
      )
      return
    }
    expr.type = subtype
  }

  public override func visitExtensionExpr(_ expr: ExtensionExpr) {
    guard let decl = context.decl(for: expr.type!) else {
      error(
        SemaError.unknownType(type: expr.type!),
        loc: expr.startLoc(),
        highlights: [expr.typeRef.name.range]
      )
      return
    }
    withTypeDecl(decl) {
      super.visitExtensionExpr(expr)
    }
    expr.decl = decl
  }

  public override func visitContinueExpr(_ expr: ContinueExpr) {
    if currentBreakTarget == nil {
      error(
        SemaError.continueNotAllowed,
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
    }
  }

  public override func visitBreakExpr(_ expr: BreakExpr) {
    if currentBreakTarget == nil {
      error(
        SemaError.breakNotAllowed,
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
    }
  }

  public override func visitTypeAliasExpr(_ expr: TypeAliasExpr) {
    guard let bound = expr.bound.type else { return }
    guard context.isValidType(bound) else {
      error(
        SemaError.unknownType(type: bound),
        loc: expr.bound.startLoc(),
        highlights: [expr.bound.sourceRange]
      )
      return
    }
  }

  public override func visitVarExpr(_ expr: VarExpr) {
    super.visitVarExpr(expr)

    if let fn = currentFunction,
       fn.isInitializer,
       expr.name == "self"
    {
      expr.decl = VarAssignExpr(name: "self", typeRef: fn.returnType)
      expr.isSelf = true
      expr.type = fn.returnType.type!
      return
    }

    let candidates = context.functions(named: expr.name)
    if let decl = varBindings[expr.name.name] ?? context.global(named: expr.name) {
      expr.decl = decl
      expr.type = decl.type
      if let de = decl as? FuncArgumentAssignExpr, de.isImplicitSelf {
        expr.isSelf = true
      }
    } else if !candidates.isEmpty {
      if let fnDecl = candidates.first, candidates.count == 1 {
        expr.decl = fnDecl
        expr.type = fnDecl.type
      } else {
        error(
          SemaError.ambiguousReference(name: expr.name),
          loc: expr.startLoc(),
          highlights: [expr.sourceRange]
        )
        return
      }
    }
    guard let decl = expr.decl else {
      error(
        SemaError.unknownVariableName(name: expr.name),
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
      return
    }
    if let closure = currentClosure {
      closure.add(capture: decl)
    }
  }

  public override func visitFuncCallExpr(_ expr: FuncCallExpr) {
    expr.args.forEach {
      visit($0.val)
    }
    expr.args.forEach {
      guard $0.val.type != nil else { return }
    }
    var candidates = [FuncDeclExpr]()
    var name: Identifier? = nil
    switch expr.lhs {
    case let lhs as FieldLookupExpr:
      let assignedToField = visitFieldLookupExpr(lhs, callArgs: expr.args)
      guard let typeDecl = lhs.typeDecl else { return }
      if case .function(let args, let ret)? = lhs.type, assignedToField {
        let candidate = foreignDecl(args: args, ret: ret)
        candidates.append(candidate)
      }
      candidates += typeDecl.methods(named: lhs.name.name)
      name = lhs.name
    case let lhs as VarExpr:
      name = lhs.name
      if let typeDecl = context.decl(for: DataType(name: lhs.name.name)) {
        candidates.append(contentsOf: typeDecl.initializers)
      } else if let varDecl = varBindings[lhs.name.name] {
        let type = context.canonicalType(varDecl.type)
        if case .function(let args, let ret) = type {
          candidates += [foreignDecl(args: args, ret: ret)]
        } else {
          error(
            SemaError.callNonFunction(type: type),
            loc: lhs.startLoc(),
            highlights: [expr.sourceRange]
          )
          return
        }
      } else {
        candidates += context.functions(named: lhs.name)
      }
    default:
      visit(expr.lhs)
      if case .function(let args, let ret)? = expr.lhs.type {
        candidates += [foreignDecl(args: args, ret: ret)]
      } else {
        error(
          SemaError.callNonFunction(type: expr.lhs.type ?? .void),
          loc: expr.lhs.startLoc(),
          highlights: [expr.lhs.sourceRange]
        )
        return
      }
    }

    guard !candidates.isEmpty else {
      error(
        SemaError.unknownFunction(name: name!),
        loc: name?.range?.start,
        highlights: [name?.range]
      )
      return
    }

    guard let decl = candidate(forArgs: expr.args, candidates: candidates) else {
      error(
        SemaError.noViableOverload(name: name!, args: expr.args),
        loc: name?.range?.start,
        highlights: [name?.range]
      )
      return
    }
    expr.decl = decl
    expr.type = decl.returnType.type

    if let lhs = expr.lhs as? FieldLookupExpr {
      if case .immutable(let culprit) = context.mutability(of: lhs),
         decl.has(attribute: .mutating), decl.parentType != nil
      {
        error(
          SemaError.assignToConstant(name: culprit),
          loc: name?.range?.start,
          highlights: [name?.range]
        )
        return
      }
    }
  }

  public override func visitCompoundExpr(_ expr: CompoundExpr) {
    for (idx, e) in expr.exprs.enumerated() {
      visit(e)
      let isLast = idx == (expr.exprs.endIndex - 1)
      let isReturn = e is ReturnExpr
      let isBreak = e is BreakExpr
      let isContinue = e is ContinueExpr
      let isNoReturnFuncCall: Bool = {
        if let c = e as? FuncCallExpr {
          return c.decl?.has(attribute: .noreturn) == true
        }
        return false
      }()

      if !expr.hasReturn {
        if isReturn || isNoReturnFuncCall {
          expr.hasReturn = true
        } else if let ifExpr = e as? IfExpr,
                  let elseBody = ifExpr.elseBody
        {
          var hasReturn = true
          for block in ifExpr.blocks where !block.1.hasReturn {
            hasReturn = false
          }
          if hasReturn {
            hasReturn = elseBody.hasReturn
          }
          expr.hasReturn = hasReturn
        }
      }

      if (isReturn || isBreak || isContinue || isNoReturnFuncCall) && !isLast {
        let type =
          isReturn ? "return" :
          isContinue ? "continue" :
          isNoReturnFuncCall ? "call to noreturn function" : "break"
        warning(
          "Code after \(type) will not be executed.",
          loc: e.startLoc(),
          highlights: [expr.sourceRange]
        )
      }
    }
  }

  public override func visitClosureExpr(_ expr: ClosureExpr) {
    super.visitClosureExpr(expr)
    var argTys = [DataType]()
    expr.args.forEach {
      argTys.append($0.type)
    }
    expr.type = .function(args: argTys, returnType: expr.returnType.type!)
  }

  public override func visitSwitchExpr(_ expr: SwitchExpr) {
    super.visitSwitchExpr(expr)
    guard let valueType = expr.value.type else { return }
    for c in expr.cases {
      let fakeInfix = InfixOperatorExpr(
        op: .equalTo,
        lhs: expr.value,
        rhs: c.constant
      )
      guard let ty = fakeInfix.type(forArgType: c.constant.type!),
            !ty.isPointer else
      {
        error(
          SemaError.cannotSwitch(type: valueType),
          loc: expr.value.startLoc(),
          highlights: [expr.value.sourceRange]
        )
        continue
      }
    }
  }

  public override func visitPrefixOperatorExpr(_ expr: PrefixOperatorExpr) {
    super.visitPrefixOperatorExpr(expr)

    guard let rhsType = expr.rhs.type else { return }
    guard let exprType = expr.type(forArgType: rhsType) else {
      error(
        SemaError.invalidOperands(op: expr.op, invalid: rhsType),
        loc: expr.opRange?.start,
        highlights: [expr.opRange, expr.rhs.sourceRange]
      )
      return
    }
    expr.type = exprType

    if expr.op == .star {
      guard case .pointer = rhsType else {
        error(
          SemaError.dereferenceNonPointer(type: rhsType),
          loc: expr.opRange?.start,
          highlights: [expr.opRange, expr.rhs.sourceRange]
        )
        return
      }
    }

    if expr.op == .ampersand {
      guard expr.rhs is VarExpr || expr.rhs is SubscriptExpr || expr.rhs is FieldLookupExpr else {
        error(
          SemaError.addressOfRValue,
          loc: expr.opRange?.start,
          highlights: [expr.opRange, expr.rhs.sourceRange]
        )
        return
      }
    }
  }

  public override func visitInfixOperatorExpr(_ expr: InfixOperatorExpr) {
    super.visitInfixOperatorExpr(expr)

    guard var lhsType = expr.lhs.type,
          var rhsType = expr.rhs.type else
    {
      return
    }
    let canLhs = context.canonicalType(lhsType)
    let canRhs = context.canonicalType(rhsType)

    if case .int = canLhs, expr.rhs is NumExpr {
      expr.rhs.type = lhsType
      rhsType = lhsType
    } else if case .int = canRhs, expr.lhs is NumExpr {
      expr.lhs.type = rhsType
      lhsType = rhsType
    }

    if case .pointer = canLhs, expr.rhs is NilExpr {
      expr.rhs.type = lhsType
      rhsType = lhsType
    } else if case .pointer = canRhs, expr.lhs is NilExpr {
      expr.lhs.type = rhsType
      lhsType = rhsType
    }

    if expr.op.isAssign {
      expr.type = .void
      if case .immutable(let name) = context.mutability(of: expr.lhs) {
        if currentFunction == nil || !currentFunction!.isInitializer {
          error(
            SemaError.assignToConstant(name: name),
            loc: name?.range?.start,
            highlights: [name?.range]
          )
          return
        }
      }

      if expr.rhs is NilExpr, let lhsType = expr.lhs.type {
        let canLhs = context.canonicalType(lhsType)
        guard case .pointer = canLhs else {
          error(
            SemaError.nonPointerNil(type: lhsType),
            loc: expr.lhs.startLoc(),
            highlights: [expr.lhs.sourceRange, expr.rhs.sourceRange]
          )
          return
        }
      }
    }

    if case .as = expr.op {
      guard context.isValidType(expr.rhs.type!) else {
        error(
          SemaError.unknownType(type: expr.rhs.type!),
          loc: expr.rhs.startLoc(),
          highlights: [expr.rhs.sourceRange]
        )
        return
      }

      if !context.canCoerce(canLhs, to: canRhs) {
        error(
          SemaError.cannotCoerce(type: lhsType, toType: rhsType),
          loc: expr.opRange?.start,
          highlights: [expr.lhs.sourceRange, expr.opRange, expr.rhs.sourceRange]
        )
      }
      expr.type = rhsType
    } else {
      if let exprType = expr.type(forArgType: lhsType) {
        expr.type = exprType
      } else {
        expr.type = .void
      }
    }
  }

  public override func visitTernaryExpr(_ expr: TernaryExpr) {
    super.visitTernaryExpr(expr)
    expr.type = expr.trueCase.type
  }

  public override func visitPoundFunctionExpr(_ expr: PoundFunctionExpr) {
    super.visitPoundFunctionExpr(expr)
    guard let funcDecl = currentFunction else {
      error(
        SemaError.poundFunctionOutsideFunction,
        loc: expr.startLoc(),
        highlights: [expr.sourceRange]
      )
      return
    }
    expr.value = funcDecl.formattedName
  }

  public override func visitPoundDiagnosticExpr(_ expr: PoundDiagnosticExpr) {
    if expr.isError {
      context.diag.error(expr.text, loc: expr.content.startLoc())
    } else {
      context.diag.warning(expr.text, loc: expr.content.startLoc())
    }
  }

  public override func visitReturnExpr(_ expr: ReturnExpr) {
    guard let returnType = currentClosure?.returnType.type ?? currentFunction?.returnType.type else { return }
    let canRet = context.canonicalType(returnType)
    if case .int = canRet, expr.value is NumExpr {
      expr.value.type = returnType
    }

    if case .pointer = canRet, expr.value is NilExpr {
      expr.value.type = returnType
    }

    super.visitReturnExpr(expr)
  }

  // MARK: Internal

  var varBindings = [String: VarAssignExpr]()

  // MARK: Private

  private func registerTopLevelDecls(in context: ASTContext) {
    for expr in context.extensions {
      guard let typeDecl = context.decl(for: expr.type!) else {
        error(
          SemaError.unknownType(type: expr.type!),
          loc: expr.startLoc(),
          highlights: [expr.sourceRange]
        )
        continue
      }
      for method in expr.methods {
        typeDecl.addMethod(method, named: method.name.name)
      }
    }
    for expr in context.types {
      let oldBindings = varBindings
      defer {
        varBindings = oldBindings
      }
      var fieldNames = Set<String>()
      for field in expr.fields {
        field.containingTypeDecl = expr
        if fieldNames.contains(field.name.name) {
          error(
            SemaError.duplicateField(name: field.name, type: expr.type),
            loc: field.startLoc(),
            highlights: [expr.name.range]
          )
          continue
        }
        fieldNames.insert(field.name.name)
      }
      var methodNames = Set<String>()
      for method in expr.methods {
        let mangled = Mangler.mangle(method)
        if methodNames.contains(mangled) {
          error(
            SemaError.duplicateMethod(name: method.name, type: expr.type),
            loc: method.startLoc(),
            highlights: [expr.name.range]
          )
          continue
        }
        methodNames.insert(mangled)
      }
      if context.isCircularType(expr) {
        error(
          SemaError.referenceSelfInProp(name: expr.name),
          loc: expr.startLoc(),
          highlights: [expr.name.range]
        )
      }
    }
  }

  private func foreignDecl(args: [DataType], ret: DataType) -> FuncDeclExpr {
    let assigns: [FuncArgumentAssignExpr] = args.map {
      let name = Identifier(name: "__implicit__")
      return FuncArgumentAssignExpr(
        name: "",
        type: TypeRefExpr(type: $0, name: name)
      )
    }
    let retName = Identifier(name: "\(ret)")
    let typeRef = TypeRefExpr(type: ret, name: retName)
    return FuncDeclExpr(
      name: "",
      returnType: typeRef,
      args: assigns,
      body: nil,
      attributes: [.foreign, .implicit]
    )
  }

  private func candidate(forArgs args: [Argument], candidates: [FuncDeclExpr]) -> FuncDeclExpr? {
    loop: for candidate in candidates {
      var candidateArgs = candidate.args
      if let first = candidateArgs.first, first.isImplicitSelf {
        candidateArgs.remove(at: 0)
      }
      if !candidate.hasVarArgs && candidateArgs.count != args.count {
        continue loop
      }
      for (candArg, exprArg) in zip(candidateArgs, args) {
        if let externalName = candArg.externalName,
           exprArg.label != externalName
        {
          continue loop
        }
        guard var valType = exprArg.val.type else { continue loop }
        let type = context.canonicalType(candArg.type)
        // automatically coerce number literals.
        if case .int = type, exprArg.val is NumExpr {
          valType = type
          exprArg.val.type = valType
        } else if case .pointer = type, exprArg.val is NilExpr {
          valType = type
          exprArg.val.type = valType
        }
        if !matches(type, .any) && !matches(type, valType) {
          continue loop
        }
      }
      return candidate
    }
    return nil
  }

}
