//
//  SourceLocation.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - SourceLocation

public struct SourceLocation: CustomStringConvertible, Comparable {

  // MARK: Lifecycle

  init(line: Int, column: Int, charOffset: Int = 0) {
    self.line = line
    self.column = column
    self.charOffset = charOffset
  }

  // MARK: Public

  public var description: String {
    "<line: \(line), column: \(column)>"
  }

  public static func ==(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
    if lhs.charOffset == rhs.charOffset {
      return true
    }
    return lhs.line == rhs.line && lhs.column == rhs.column
  }

  public static func <(lhs: SourceLocation, rhs: SourceLocation) -> Bool {
    if lhs.charOffset < rhs.charOffset { return true }
    if lhs.line < rhs.line { return true }
    return lhs.column < rhs.column
  }

  // MARK: Internal

  static let zero = SourceLocation(line: 0, column: 0)

  var line: Int
  var column: Int
  var charOffset: Int

}

// MARK: - SourceRange

public struct SourceRange {
  static let zero = SourceRange(start: .zero, end: .zero)

  let start: SourceLocation
  let end: SourceLocation

}
