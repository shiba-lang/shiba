//
//  Decl.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
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
    rawValue
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
