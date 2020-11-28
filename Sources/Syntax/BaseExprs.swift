//
//  Expr.swift
//  Shiba
//
//  Created by Khoa Le on 27/11/2020.
//

import Foundation

// MARK: - DeclContextKind

enum DeclContextKind {
  case function
  case variable
  case type
  case `extension`
  case diagnostic
}

// MARK: - DeclAccessKind

enum DeclAccessKind: String, CustomStringConvertible {
  case foreign = "foreign"
  case mutating = "mutating"
  case noreturn = "noreture"
  case `static` = "static"
  case indirect = "indirect"
  case implicit = "implicit"

  // MARK: Internal

  var description: String {
    return rawValue
  }

  func isValid(on kind: DeclContextKind) -> Bool {
    switch (self, kind) {
    case (.foreign, .function),
         (.foreign, .type),
         (.foreign, .variable),
         (.static, .function),
         (.mutating, .function),
         (.noreturn, .function),
         (.indirect, .type),
         (.implicit, .type),
         (.implicit, .function),
         (.implicit, .variable):
      return true
    default:
      return false
    }
  }

}

// MARK: - SourceLocation

struct SourceLocation: CustomStringConvertible, Equatable {
  static let zero = SourceLocation(line: 0, column: 0)

  var line: Int
  var column: Int
  var charOffset: Int = 0

  var description: String {
    return "<line: \(line), column: \(column)"
  }

  static func ==(lhs: Self, rhs: Self) -> Bool {
    if lhs.charOffset == rhs.charOffset {
      return true
    }
    return lhs.line == rhs.line && lhs.column == rhs.column
  }

  static func <(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
    if lhs.charOffset < rhs.charOffset { return true }
    if lhs.line < rhs.line { return true }
    return lhs.column < rhs.column
  }
}

// MARK: - SourceRange

struct SourceRange {
  static let zero = SourceRange(start: .zero, end: .zero)

  let start: SourceLocation
  let end: SourceLocation

}

// MARK: - Identifier

struct Identifier: CustomStringConvertible, Equatable, Hashable, ExpressibleByStringLiteral {

  // MARK: Lifecycle

  init(name: String, range: SourceRange? = nil) {
    self.name = name
    self.range = range
  }

  init(stringLiteral name: String) {
    self.name = name
    range = nil
  }

  init(unicodeScalarLiteral name: String) {
    self.name = name
    range = nil
  }

  init(extendedGraphemeCluserLiteral name: ExtendedGraphemeClusterType) {
    self.name = name
    range = nil
  }

  // MARK: Internal

  let name: String
  let range: SourceRange?

  var description: String {
    return name
  }

  static func ==(lhs: Identifier, rhs: Identifier) -> Bool {
    return lhs.name == rhs.name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(0x23423378)
  }

}

// MARK: - Expr

class Expr: Equatable, Hashable {

  // MARK: Lifecycle

  init(sourceRange: SourceRange? = nil) {
    self.sourceRange = sourceRange
  }

  // MARK: Internal

  let sourceRange: SourceRange?

  static func ==(lhs: Expr, rhs: Expr) -> Bool {
    return lhs.equals(rhs)
  }

  func startLoc() -> SourceLocation? {
    return sourceRange?.start
  }

  func endLoc() -> SourceLocation? {
    return sourceRange?.end
  }

  func equals(_ rhs: Expr) -> Bool {
    return false
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
    hasher.combine(0x3a0395ca)
  }

}

final class BindingExpr: Expr {
	let name: Identifier
	init(name: Identifier, sourceRange: SourceRange? = nil) {
		self.name = name
		super.init(sourceRange: sourceRange)
	}

	override func equals(_ rhs: Expr) -> Bool {
		guard let rhs = rhs as? BindingExpr else { return false }
		return name == rhs.name
	}
}
