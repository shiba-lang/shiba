//
//  DiagnosticEngine.swift
//  Shiba
//
//  Created by Khoa Le on 29/11/2020.
//

import Foundation

// MARK: - Diagnostic

/// Represents a diagnostic that expresses a failure or warning condition found
/// during compilation.
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
    /// The message is a warning that will not prevent compilation but that
    /// the shiba compiler feels might signal code that does not behave the way
    /// the programmer expected.
    case warning

    /// The message is an error that violates a rule for the shiba language.
    /// This error might not necessarily prevent further processing of the
    /// source file after it is emitted, but will ultimatelly prevent shiba from
    /// producing an executable
    case error

    // MARK: Internal

    var description: String {
      self == .warning ? "warning" : "error"
    }
  }

  /// The textual message that the diagnostic intends to print.
  let message: String

  /// The type can be diag with.
  let diagnosticType: DiagnosticType

  /// The location this diagnostic is associated with.
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

  /// Adds a highlighted to this.
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

/// A DiagnosticEngine is a container for diagnostics that have been emitted
/// while compiling a shiba program. It exposes an interface for emitting errors
/// and warnings and allows for iteration over diagnostics after the fact.
public final class DiagnosticEngine {

  /// The current set of emitted warnings.
  private(set) var warnings = [Diagnostic]()

  /// The current set of emitted errors.
  private(set) var errors = [Diagnostic]()

  /// The set of consumers receiving diagnostics notifications from this engine.
  private(set) var consumers = [DiagnosticConsumer]()

  /// Determines if the engine has any `.error` diagnostics registered.
  var hasErrors: Bool {
    !errors.isEmpty
  }

  // MARK: Public

  /// Adds a diagnostic consumer to the engine to receive diagnostic updates
  ///
  /// - Parameter consumer: The consumer that will observe diagnostics
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
