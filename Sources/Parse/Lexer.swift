//
//  Lexer.swift
//  Shiba
//
//  Created by Khoa Le on 27/11/2020.
//

import Foundation

// MARK: - LexError

fileprivate enum LexError: Error, CustomStringConvertible {
  case invalidCharacterLiteral(literal: String)
  case unexpectedEOF
  case invalidEscape(escapeChar: UnicodeScalar)

  // MARK: Internal

  var description: String {
    switch self {
    case .invalidCharacterLiteral(let literal):
      return "invalid character literal '\(literal)' in source file"
    case .invalidEscape(let escapeChar):
      return "invalid character escape '\(escapeChar)'"
    case .unexpectedEOF:
      return "unexpected EOF"
    }
  }
}

// MARK: - Lexer

final class Lexer {

  // MARK: Lifecycle

  init(input: String) {
    characters = Array(input.unicodeScalars)
  }

  // MARK: Internal

  var sourceLocation = SourceLocation(line: 1, column: 1)
  var characters = [UnicodeScalar]()
  var tokIndex = 0

  func lex() throws -> [Token] {
    var tokens = [Token]()
    while true {
      do {
        let tok = try advanceToNextToken()
        if case .eof = tok.kind {
          break
        }
        tokens.append(tok)
      } catch let err {
        // TODO: - Better error handling
        print("failed to lex: \(err.localizedDescription) at \(sourceLocation)")
      }
    }
    return tokens
  }

  // MARK: Private

  private var currentChar: UnicodeScalar? {
    charAt(0)
  }

  private func charAt(_ index: Int) -> UnicodeScalar? {
    guard tokIndex + index < characters.endIndex else {
      return nil
    }
    return characters[tokIndex + index]
  }

  private func currentSubstring(_ length: Int) -> String {
    var str = ""
    for index in 0..<length {
      guard let c = charAt(index) else { continue }
      str.append(String(c))
    }
    return str
  }

  private func range(start: SourceLocation) -> SourceRange {
    SourceRange(start: start, end: sourceLocation)
  }

  private func advance(_ n: Int = 1) {
    guard let char = currentChar else { return }
    for _ in 0..<n {
      if char == "\n" {
        sourceLocation.line += 1
        sourceLocation.column = 1
      } else {
        sourceLocation.column += 1
      }
      sourceLocation.charOffset += 1
      tokIndex += 1
    }
  }

  private func advanceToNextToken() throws -> Token {
    advanceWhile {
      $0.isSpace
    }

    guard let currentChar = currentChar else {
      return Token(kind: .eof, range: range(start: sourceLocation))
    }

    if currentChar == "\n" {
      defer {
        advanceWhile { $0.isSpace || $0.isLineSeparator }
      }
      return Token(kind: .newline, range: range(start: sourceLocation))
    }

    if currentChar == ";" {
      defer {
        advanceWhile { $0.isSpace || $0.isLineSeparator }
      }
      return Token(kind: .semicolon, range: range(start: sourceLocation))
    }

    // skip comments
    if currentChar == "/" {
      // skip `//`
      if charAt(1) == "/" {
        advanceWhile {
          $0 != "\n"
        }
        return try advanceToNextToken()
      } else if charAt(1) == "*" {
        // skip `/*`
        advanceWhile { _ in
          currentSubstring(2) != "*/"
        }
        advance()
        advance()
        return try advanceToNextToken()
      }
    }

    /// Fix issue #2
    let startLocation = sourceLocation

    if currentChar == "[" {
      advance()
      return Token(kind: .leftSquare, range: range(start: startLocation))
    }

    if currentChar == "]" {
      advance()
      return Token(kind: .rightSquare, range: range(start: startLocation))
    }

    if currentSubstring(3) == "..." {
      advance(3)
      return Token(kind: .ellipsis, range: range(start: startLocation))
    }

    if currentChar == "'" {
      advance()
      let scalar = try readCharacter()
      let value = UInt8(scalar.value & 0xff)
      guard self.currentChar == "'" else {
        throw LexError.invalidCharacterLiteral(literal: "\(value)")
      }
      advance()
      return Token(kind: .char(value: value), range: range(start: startLocation))
    }

    if currentChar == "\"" {
      advance()
      var str = ""
      while self.currentChar != "\"" {
        str.append(String(try readCharacter()))
      }
      advance()
      return Token(
        kind: .stringLiteral(value: str),
        range: range(start: startLocation)
      )
    }

    if currentChar.isIdentifier {
      let id = collectWhile { $0.isIdentifier }
      if let numVal = id.asNumber() {
        return Token(
          kind: .number(value: numVal, raw: id),
          range: range(start: startLocation)
        )
      } else {
        return Token(
          kind: TokenKind(identifier: id),
          range: range(start: startLocation)
        )
      }
    }

    if currentChar.isOperator {
      let str = collectWhile { $0.isOperator }
      if let op = BuiltinOperator(rawValue: str) {
        return Token(kind: .operator(op: op), range: range(start: startLocation))
      } else {
        return Token(
          kind: TokenKind(op: str),
          range: range(start: startLocation)
        )
      }
    }

    advance()
    let kind = TokenKind(op: String(currentChar))
    return Token(kind: kind, range: range(start: startLocation))
  }

  private func advanceIf(
    _ f: (UnicodeScalar) -> Bool,
    completion: () -> Void = {}
  ) -> Bool {
    guard let char = currentChar else { return false }
    if f(char) {
      completion()
      advance()
      return true
    }
    return false
  }

  private func advanceWhile(
    _ f: (UnicodeScalar) -> Bool,
    completion: () -> Void = {}
  ) {
    while advanceIf(f, completion: completion) {}
  }

  private func collectWhile(_ f: (UnicodeScalar) -> Bool) -> String {
    var str = ""
    advanceWhile(f) {
      guard let c = currentChar else { return }
      str.append(String(c))
    }
    return str
  }

  private func readCharacter() throws -> UnicodeScalar {
    if currentChar == "\\" {
      advance()
      switch currentChar {
      case "n"?:
        advance()
        return "\n" as UnicodeScalar
      case "t"?:
        advance()
        return "\t" as UnicodeScalar
      case "r":
        advance()
        return "\r" as UnicodeScalar
      case "\""?:
        advance()
        return "\"" as UnicodeScalar
      default:
        throw LexError.invalidEscape(escapeChar: currentChar!)
      }
    } else if let currentChar = currentChar {
      advance()
      return currentChar
    } else {
      throw LexError.unexpectedEOF
    }
  }
}


