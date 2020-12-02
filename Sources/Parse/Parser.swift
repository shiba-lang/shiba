//
//  Parser.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - ParseError

enum ParseError: Error, CustomStringConvertible {
  case unexpectedToken(token: TokenKind)
  case missingLineSeparator
  case expectedIdentifier(got: TokenKind)
  case duplicateDefault
  case caseMustBeConstant
  case unexpectedExpression(expected: String)
  case duplicateDeinit
  case invalidAttribute(DeclContextKind, DeclAccessKind)

  // MARK: Internal

  var description: String {
    switch self {
    case let .unexpectedToken(token):
      return "unexpected token '\(token.text)'"
    case .missingLineSeparator:
      return "missing line separator"
    case let .expectedIdentifier(got):
      return "unexpected identifier (got '\(got.text)')"
    case .duplicateDefault:
      return "only one default statement is allowed in a switch"
    case .caseMustBeConstant:
      return "case statement expressions must be constants"
    case let .unexpectedExpression(expected):
      return "unexpected expression (expected '\(expected)')"
    case .duplicateDeinit:
      return "cannot have multiple 'deinit's within a type"
    case let .invalidAttribute(attr, kind):
      return "'\(attr)' is not valid on \(kind)s"
    }
  }
}

// MARK: - Parser

public final class Parser {

  // MARK: Lifecycle

  init(tokens: [Token], context: ASTContext) {
    self.tokens = tokens
    self.context = context
  }

  // MARK: Public

  public func parseTopLevel(into context: ASTContext) throws {
    while true {
      if case .eof = peek() {
        break
      }
      consumeLineSeparators()
      let attrs = try parseAccessAttributes()
      switch peek() {
      case .fn:
        context.add(try parseFuncDecl(attrs))
      case .typedef:
        let expr = try parseTypeDecl(attrs)
        if let typeDecl = expr as? TypeDeclExpr {
          context.add(typeDecl)
        } else if let alias = expr as? TypeDeclExpr {
          context.add(alias)
        } else {
          fatalError("non type expr returned from parseTypeDecl()")
        }
      case .extension:
        context.add(try parseExtensionDecl())
        break
      case .let, .mut:
        context.add(try parseVarAssignDecl(attrs))
      case .poundWarning, .poundError:
        context.add(try parsePoundDiagnosticExpr())
      default:
        let err = ParseError.unexpectedExpression(expected: "function, type, or extension")
        throw Diagnostic.error(err, loc: sourceLoc)
      }
      try consumeAtLeastOneLineSeparator()
    }
  }

  // MARK: Internal

  var tokIndex = 0
  var tokens: [Token]
  let context: ASTContext

  var currentToken: Token {
    guard tokens.indices.contains(tokIndex) else {
      return Token(kind: .eof, range: .zero)
    }
    return tokens[tokIndex]
  }

  var sourceLoc: SourceLocation {
    currentToken.range.start
  }

  func range(start: SourceLocation) -> SourceRange {
    let end: SourceLocation
    if tokens.indices.contains(tokIndex - 1) {
      let t = tokens[tokIndex - 1]
      end = t.range.end
    } else {
      end = start
    }
    return SourceRange(start: start, end: end)
  }

  func missingLineSeparator() -> Error {
    let endLoc = adjustedEnd()
    return Diagnostic.error(ParseError.missingLineSeparator, loc: endLoc)
  }

  func unexpectedToken() -> Error {
    let end = adjustedEnd()
    return Diagnostic.error(
      ParseError.unexpectedToken(token: peek()),
      loc: end,
      highlights: [
        currentToken.range,
      ]
    )
  }

  func attempt<T>(_ block: @autoclosure () throws -> T) throws -> T {
    let startIndex = tokIndex
    do {
      return try block()
    } catch {
      tokIndex = startIndex
      throw error
    }
  }

  func peek(ahead offset: Int = 0) -> TokenKind {
    let idx = tokIndex + offset
    guard tokens.indices.contains(idx) else {
      return .eof
    }
    return tokens[idx].kind
  }

  @discardableResult
  func consumeToken() -> Token {
    let c = currentToken
    tokIndex += 1
    while case .newline = peek() {
      tokIndex += 1
    }
    return c
  }

  func consume(_ token: TokenKind) throws {
    guard token == peek() else {
      throw unexpectedToken()
    }
    consumeToken()
  }

  func consumeAtLeastOneLineSeparator() throws {
    if case .eof = peek() {
      return
    }
    if [.newline, .semicolon].contains(peek()) {
      consumeToken()
    } else if ![.newline, .semicolon].contains(peek(ahead: -1)) {
      throw missingLineSeparator()
    }
    consumeLineSeparators()
  }

  // MARK: Private

  private func adjustedEnd() -> SourceLocation {
    if tokens.indices.contains(tokIndex - 1) {
      let tok = tokens[tokIndex - 1]
      return tok.range.end
    } else {
      return SourceLocation(line: 1, column: 1)
    }
  }

  private func consumeLineSeparators() {
    while [.newline, .semicolon].contains(peek()) {
      tokIndex += 1
    }
  }
}

extension Parser {
  func parseIdentifier() throws -> Identifier {
    guard case let .identifier(name) = peek() else {
      let error = ParseError.expectedIdentifier(got: peek())
      throw Diagnostic.error(error, loc: sourceLoc)
    }
    return Identifier(name: name, range: consumeToken().range)
  }

  func parseAccessAttributes() throws -> [DeclAccessKind] {
    var attrs = [DeclAccessKind]()
    while case let .identifier(attrId) = peek() {
      if let attr = DeclAccessKind(rawValue: attrId) {
        consumeToken()
        attrs.append(attr)
      } else {
        let error = ParseError.expectedIdentifier(got: peek())
        throw Diagnostic.error(error, loc: sourceLoc)
      }
    }
    let nextKind: DeclContextKind
    switch peek() {
    case .fn, .Init, .deinit:
      nextKind = .function
    case .let, .mut:
      nextKind = .variable
    case .typedef:
      nextKind = .type
    case .extension:
      nextKind = .extension
    case .poundWarning, .poundError:
      nextKind = .diagnostic
    default:
      throw unexpectedToken()
    }
    for attr in attrs {
      if !attr.isValid(on: nextKind) {
        let error = ParseError.invalidAttribute(nextKind, attr)
        throw Diagnostic.error(error, loc: sourceLoc)
      }
    }
    return attrs
  }

  /// Braced Expression Block
  ///
  /// {
  /// [<if-expr>        |
  /// <while-expr>      |
  /// <var-assign-expr> |
  /// <return-expr>     |
  /// <val-expr>];*
  ///}
  func parseCompoundExpr() throws -> CompoundExpr {
    let startLoc = sourceLoc
    try consume(.leftBrace)
    let exprs = try parseStatementExprs(terminators: [.rightBrace])
    consumeToken()
    return CompoundExpr(exprs: exprs, sourceRange: range(start: startLoc))
  }

  func parseStatementExprs(terminators: [TokenKind]) throws -> [Expr] {
    var exprs = [Expr]()
    while !terminators.contains(peek()) {
      let expr = try parseStatementExpr()
      if !terminators.contains(peek()) {
        try consumeAtLeastOneLineSeparator()
      }
      if let diag = expr as? PoundDiagnosticExpr {
        context.add(diag)
      } else {
        exprs.append(expr)
      }
    }
    return exprs
  }

  func parseStatementExpr() throws -> Expr {
    let tok = peek()
    switch tok {
    case .if:
      return try parseIfExpr()
    case .while:
      return try parseWhileExpr()
    case .for:
      return try parseForLoopExpr()
    case .switch:
      return try parseSwitchExpr()
    case .let, .mut:
      return try parseVarAssignDecl()
    case .break:
      return try parseBreakExpr()
    case .continue:
      return try parseContinueExpr()
    case .return:
      return try parseReturnExpr()
    case .poundError, .poundWarning:
      return try parsePoundDiagnosticExpr()
    default:
      return try parseValExpr()
    }
  }

  /// Type Declaration
  ///
  /// type-decl ::= typedef <typename> {
  /// 	[<field-decl> | <fn-decl>]*
  /// }
  func parseTypeDecl(_ attributes: [DeclAccessKind]) throws -> Expr {
    try consume(.typedef)
    let startLoc = sourceLoc
    let name = try parseIdentifier()

    if case .operator(op: .assign) = peek() {
      consumeToken()
      let bound = try parseType()
      return TypeAliasExpr(
        name: name,
        bound: bound,
        sourceRange: range(start: startLoc)
      )
    }
    try consume(.leftBrace)
    var fields = [VarAssignExpr]()
    var methods = [FuncDeclExpr]()
    var initializers = [FuncDeclExpr]()
    var deinitializer: FuncDeclExpr?
    let type = DataType(name: name.name)
    loop: while true {
      if case .rightBrace = peek() {
        consumeToken()
        break
      }
      let attrs = try parseAccessAttributes()
      switch peek() {
      case .fn:
        methods.append(try parseFuncDecl(attrs, forType: type))
      case .Init:
        initializers.append(try parseFuncDecl(attrs, forType: type))
      case .deinit:
        if deinitializer != nil {
          let err = ParseError.duplicateDeinit
          throw Diagnostic.error(err, loc: sourceLoc)
        }
        deinitializer = try parseFuncDecl(
          attributes,
          forType: type,
          isDeinit: true
        )
      case .mut, .let:
        fields.append(try parseVarAssignDecl(attrs))
      case .poundError, .poundWarning:
        context.add(try parsePoundDiagnosticExpr())
      default:
        throw unexpectedToken()
      }
      try consumeAtLeastOneLineSeparator()
    }
    return TypeDeclExpr(
      name: name,
      fields: fields,
      methods: methods,
      initializers: initializers,
      attributes: attributes,
      deinit: deinitializer,
      sourceRange: range(start: startLoc)
    )
  }

  func parseExtensionDecl() throws -> ExtensionExpr {
    let startLoc = sourceLoc
    try consume(.extension)
    let type = try parseType()
    guard case .leftBrace = peek() else {
      throw unexpectedToken()
    }
    consumeToken()
    var methods = [FuncDeclExpr]()
    while true {
      if case .rightBrace = peek() {
        consumeToken()
        break
      }
      let attrs = try parseAccessAttributes()
      guard case .fn = peek() else {
        let err = ParseError.unexpectedExpression(expected: "function")
        throw Diagnostic.error(err, loc: sourceLoc)
      }
      let method = try parseFuncDecl(attrs, forType: type.type)
      methods.append(method)
    }
    return ExtensionExpr(
      type: type,
      methods: methods,
      sourceRange: range(start: startLoc)
    )
  }
}
