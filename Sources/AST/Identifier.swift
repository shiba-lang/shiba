//
//  Identifier.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - Identifier

public struct Identifier:
  CustomStringConvertible,
  Equatable,
  Hashable,
  ExpressibleByStringLiteral
{

  // MARK: Lifecycle

  public init(name: String, range: SourceRange? = nil) {
    self.name = name
    self.range = range
  }

  public init(stringLiteral name: String) {
    self.name = name
    range = nil
  }

  public init(unicodeScalarLiteral name: String) {
    self.name = name
    range = nil
  }

  private init(extendedGraphemeCluserLiteral name: ExtendedGraphemeClusterType) {
    self.name = name
    range = nil
  }

  // MARK: Public

  public var description: String {
    name
  }

  public static func ==(lhs: Identifier, rhs: Identifier) -> Bool {
    lhs.name == rhs.name
  }


  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(0x23423378)
  }

  // MARK: Internal

  let name: String
  let range: SourceRange?

}
