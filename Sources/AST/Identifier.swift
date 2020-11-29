//
//  Identifier.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

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
    name
  }

  static func ==(lhs: Identifier, rhs: Identifier) -> Bool {
    lhs.name == rhs.name
  }


  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(0x23423378)
  }

}
