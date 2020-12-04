//
//  DiagnosticEngine.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - Diagnostic

public struct Diagnostic: Error, CustomStringConvertible {

  // MARK: Public

  public var description: String {
    var str = ""
    if let loc = sourceLocation {
      str += "\(loc.line):\(loc.column)"
    }
    return str + "\(diagnosticType): \(message)"
  }

  // MARK: Internal

  enum DiagnosticType: CustomStringConvertible {
    case warning, error

    // MARK: Internal

    var description: String {
      self == .warning ? "warning" : "error"
    }
  }

  let message: String
  let diagnosticType: DiagnosticType
  let sourceLocation: SourceLocation?

  private(set) var highlights: [SourceRange]

  static func error(
    _ err: Error,
    loc: SourceLocation? = nil,
    highlights: [SourceRange] = []
  ) -> Diagnostic {
    Diagnostic(
      message: "\(err)",
      diagnosticType: .error,
      sourceLocation: loc,
      highlights: highlights
    )
  }

  static func warning(
    _ err: Error,
    loc: SourceLocation? = nil,
    highlights: [SourceRange] = []
  ) -> Diagnostic {
    Diagnostic(
      message: "\(err)",
      diagnosticType: .warning,
      sourceLocation: loc,
      highlights: highlights
    )
  }

  func highlighting(_ range: SourceRange?) -> Diagnostic {
    guard let range = range else { return self }
    var c = self
    c.highlight(range)
    return c
  }

  // MARK: Private

  private mutating func highlight(_ range: SourceRange?) {
    guard let range = range else { return }
    highlights.append(range)
  }

}

// MARK: - DiagnosticEngine

public class DiagnosticEngine {

  // MARK: Public

  public func register(_ consumer: DiagnosticConsumer) {
    consumers.append(consumer)
  }

  public func consumeDiagnostics() {
    let diags = (warnings + errors).sorted { a, b in
      guard let aLoc = a.sourceLocation else { return false }
      guard let bLoc = b.sourceLocation else { return true }
      return aLoc.charOffset < bLoc.charOffset
    }
    for diag in diags {
      for consumer in consumers {
        consumer.consume(diag)
      }
    }
  }

  public func error(
    _ message: String,
    loc: SourceLocation? = nil,
    highlights: [SourceRange?] = []
  ) {
    let error = Diagnostic(
      message: message,
      diagnosticType: .error,
      sourceLocation: loc,
      highlights: highlights.compactMap { $0 }
    )
    errors.append(error)
  }

  // MARK: Internal

  private(set) var warnings = [Diagnostic]()
  private(set) var errors = [Diagnostic]()
  private(set) var consumers = [DiagnosticConsumer]()

  var hasErrors: Bool {
    !errors.isEmpty
  }

  func error(
    _ err: Error,
    loc: SourceLocation? = nil,
    highlights: [SourceRange?] = []
  ) {
    error("\(err)", loc: loc, highlights: highlights)
  }

  func warning(
    _ message: String,
    loc: SourceLocation? = nil,
    highlights: [SourceRange?] = []
  ) {
    let warning = Diagnostic(
      message: message,
      diagnosticType: .warning,
      sourceLocation: loc,
      highlights: highlights.compactMap { $0 }
    )
    warnings.append(warning)
  }

  func add(error: Diagnostic) {
    errors.append(error)
  }

  func add(warning: Diagnostic) {
    warnings.append(warning)
  }

}
