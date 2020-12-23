//
//  SourceLocation.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - SourceLocation

/// Represents a source location in a Swift file.
public struct SourceLocation: CustomStringConvertible, Comparable {

  // MARK: Lifecycle

  public init(line: Int, column: Int, charOffset: Int = 0) {
    self.line = line
    self.column = column
    self.charOffset = charOffset
  }

  // MARK: Public

  /// The line in the file where this location resides. 1-based.
  public var line: Int

  /// The UTF-8 byte offset from the beginning of the line where this location
  /// resides. 1-based.
  public var column: Int

  /// The UTF-8 byte offset into the file where this location resides.
  public var charOffset: Int

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

}

// MARK: - SourceRange

/// Represents a start and end location in a Swift file.
public struct SourceRange {

  // MARK: Public

  /// The beginning location in the source range.
  public let start: SourceLocation

  /// The end location in the source range.
  public let end: SourceLocation

  // MARK: Internal

  static let zero = SourceRange(start: .zero, end: .zero)

}
