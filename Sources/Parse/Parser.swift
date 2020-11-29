//
//  Parser.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - ParseError

fileprivate enum ParseError: Error, CustomStringConvertible {
  case unexpectedToken(token: TokenKind)
  case missingLineSeparator
  case expectedIdentifier(got: TokenKind)
  case duplicateDefault
  case caseMustBeconstant
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
    case .caseMustBeconstant:
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

final class Parser {

  // MARK: Lifecycle

  init(tokens: [Token]) {
    self.tokens = tokens
  }

  //	func missingLineSeparator() -> Error {
//
  //	}


  // MARK: Internal

  var tokIndex = 0
  var tokens: [Token]

}
