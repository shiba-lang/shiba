//
//  Expr.swift
//  Shiba
//
//  Created by Khoa Le on 27/11/2020.
//

import Foundation

// MARK: - Expr

public class Expr: Equatable, Hashable {

  // MARK: Lifecycle

  public init(sourceRange: SourceRange? = nil) {
    self.sourceRange = sourceRange
  }

  // MARK: Public

  public static func ==(lhs: Expr, rhs: Expr) -> Bool {
    lhs.equals(rhs)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
    hasher.combine(0x3a0395ca)
  }

  // MARK: Internal

  let sourceRange: SourceRange?

  func startLoc() -> SourceLocation? {
    sourceRange?.start
  }

  func endLoc() -> SourceLocation? {
    sourceRange?.end
  }

  func equals(_ rhs: Expr) -> Bool {
    false
  }

}

// MARK: - BindingExpr

public class BindingExpr: Expr {

  // MARK: Lifecycle

  public init(name: Identifier, sourceRange: SourceRange? = nil) {
    self.name = name
    super.init(sourceRange: sourceRange)
  }

  // MARK: Public

  public let name: Identifier

  public override func equals(_ rhs: Expr) -> Bool {
    guard let rhs = rhs as? BindingExpr else { return false }
    return name == rhs.name
  }
}
