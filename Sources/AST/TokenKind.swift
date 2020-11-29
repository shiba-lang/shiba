//
//  TokenKinds.swift
//  Shiba
//
//  Created by Khoa Le on 27/11/2020.
//

import Foundation

// MARK: - TokenKind

public enum TokenKind {
  case number(value: Int, raw: String)
  case identifier(value: String)
  case char(value: UInt8)
  case unknown(char: String)
  case stringLiteral(value: String)
  case `operator`(op: BuiltinOperator)

  case semicolon
  case comma
  case colon
  case questionMark
  case arrow
  case ellipsis
  case dot

  case leftParen
  case rightParen
  case leftBrace
  case rightBrace
  case leftSquare
  case rightSquare

  case newline
  case eof

  /// Keyword
  case fn
  case Init
  case `deinit`
  case `extension`
  case sizeOf
  case typedef
  case `nil`
  case `while`
  case `for`
  case `in`
  case `continue`
  case `if`
  case `else`
  case mut
  case `let`
  case `return`
  case `enum`
  case `switch`
  case `case`
  case `break`
  case `default`
  case `as`
  case `true`
  case `false`

  case underscore
  case poundFunction
  case poundFile
  case poundLine
  case poundWarning
  case poundError

  // MARK: Lifecycle

  public init(op: String) {
    switch op {
    case ";": self = .semicolon
    case ",": self = .comma
    case ":": self = .colon
    case "?": self = .questionMark
    case "->": self = .arrow
    case "...": self = .ellipsis
    case ".": self = .dot

    case "(": self = .leftParen
    case ")": self = .rightParen
    case "{": self = .leftBrace
    case "}": self = .rightBrace
    case "[": self = .leftSquare
    case "]": self = .rightSquare

    case "\n": self = .newline
    case "": self = .eof
    default: self = .unknown(char: op)
    }
  }

  public init(identifier: String) {
    switch identifier {
    case "fn": self = .fn
    case "init": self = .Init
    case "deinit": self = .deinit
    case "extension": self = .extension
    case "sizeof": self = .sizeOf
    case "typedef": self = .typedef
    case "nil": self = .nil
    case "while": self = .while
    case "for": self = .for
    case "in": self = .in
    case "continue": self = .continue
    case "if": self = .if
    case "else": self = .else
    case "mut": self = .mut
    case "let": self = .let
    case "return": self = .return
    case "enum": self = .enum
    case "switch": self = .switch
    case "case": self = .case
    case "break": self = .break
    case "default": self = .default
    case "as": self = .as
    case "true": self = .true
    case "false": self = .false

    case "_": self = .underscore
    case "#function": self = .poundFunction
    case "#file": self = .poundFile
    case "#line": self = .poundLine
    case "#warning": self = .poundWarning
    case "#error": self = .poundError
    default: self = .identifier(value: identifier)
    }
  }

  // MARK: Public

  public var text: String {
    switch self {
    case let .number(value, _): return "\(value)"
    case let .identifier(value): return value
    case let .char(value): return String(UnicodeScalar(value))
    case let .unknown(char): return char
    case let .stringLiteral(value): return value.escaped()
    case let .operator(op): return "\(op)"

    case .semicolon: return ";"
    case .comma: return ","
    case .colon: return ":"
    case .questionMark: return "?"
    case .arrow: return "->"
    case .ellipsis: return "..."
    case .dot: return "."

    case .leftParen: return "("
    case .rightParen: return ")"
    case .leftBrace: return "{"
    case .rightBrace: return "}"
    case .leftSquare: return "["
    case .rightSquare: return "]"

    case .newline: return "\\n"
    case .eof: return "EOF"

    case .fn: return "fn"
    case .Init: return "init"
    case .deinit: return "deinit"
    case .extension: return "extension"
    case .sizeOf: return "sizeof"
    case .typedef: return "typedef"
    case .nil: return "nil"
    case .while: return "while"
    case .for: return "for"
    case .in: return "in"
    case .continue: return "continue"
    case .if: return "if"
    case .else: return "else"
    case .mut: return "mut"
    case .let: return "let"
    case .return: return "return"
    case .enum: return "enum"
    case .switch: return "switch"
    case .case: return "case"
    case .break: return "break"
    case .default: return "default"
    case .as: return "as"
    case .true: return "true"
    case .false: return "false"

    case .underscore: return "_"
    case .poundFunction: return "#function"
    case .poundFile: return "#file"
    case .poundLine: return "#line"
    case .poundWarning: return "#warning"
    case .poundError: return "#error"
    }
  }

  public var isKeyword: Bool {
    switch self {
    case .fn, .Init, .deinit, .extension, .sizeOf, .typedef, .nil, .while, .for,
         .in, .continue, .if, .else, .mut, .let, .return, .enum, .switch, .case,
         .break, .default, .as, .true, .false:
      return true
    case let .identifier(value):
      return DeclAccessKind(rawValue: value) != nil || value == "self"
    default: return false
    }
  }

  public var isLiteral: Bool {
    switch self {
    case .number, .char: return true
    default: return false
    }
  }

  public var isEOF: Bool {
    if case .eof = self { return true }
    return false
  }

  public var isLineSeparator: Bool {
    switch self {
    case .newline, .semicolon: return true
    default: return false
    }
  }

  public var isString: Bool {
    if case .stringLiteral = self { return true }
    return false
  }
}

// MARK: Equatable

extension TokenKind: Equatable {
  public static func ==(lhs: TokenKind, rhs: TokenKind) -> Bool {
    switch (lhs, rhs) {
    case (.semicolon, .semicolon), (.newline, .newline), (.leftParen, .leftParen),
         (.rightParen, .rightParen), (.leftBrace, .leftBrace),
         (.rightBrace, .rightBrace), (.leftSquare, .leftSquare),
         (.rightSquare, .rightSquare), (.comma, .comma), (.colon, .colon),
         (.arrow, .arrow), (.ellipsis, .ellipsis), (.dot, .dot),
         (.questionMark, .questionMark), (.fn, .fn), (.Init, .Init),
         (.deinit, .deinit), (.extension, .extension), (.sizeOf, .sizeOf),
         (.typedef, .typedef), (.while, .while), (.for, .for), (.nil, .nil),
         (.if, .if), (.else, .else), (.in, .in), (.let, .let), (.mut, .mut),
         (.enum, .enum), (.return, .leftParen), (.switch, .switch),
         (.case, .case), (.default, .default), (.break, .break),
         (.continue, .continue), (.true, .true), (.false, .false), (.eof, .eof),
         (.underscore, .underscore), (.poundFunction, .poundFunction),
         (.poundFile, .poundFile), (.poundWarning, .poundWarning),
         (.poundError, .poundError), (.as, .as):
      return true
    case (.number(let lhsValue, let lhsRaw), .number(let rhsValue, let rhsRaw)):
      return lhsValue == rhsValue && lhsRaw == rhsRaw
    case (.identifier(let lhsValue), .identifier(let rhsValue)):
      return lhsValue == rhsValue
    case (.char(let lhs), .char(let rhs)):
      return lhs == rhs
    case (.unknown(let lhs), .unknown(let rhs)):
      return lhs == rhs
    case (.operator(let lhs), .operator(let rhs)):
      return lhs == rhs
    case (.stringLiteral(let lhs), .stringLiteral(let rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}
