//
//  DiagnosticConsumer.swift
//  Shiba
//
//  Created by Khoa Le on 03/12/2020.
//

import Foundation

// MARK: - DiagnosticConsumer

/// An object that intends to receive notifications when diagnostics are emitted.
public protocol DiagnosticConsumer: AnyObject {
  /// Consume the provided diagnostic which has just been registered with the
  /// DiagnosticEngine
  func consume(_ diagnostic: Diagnostic)
}
