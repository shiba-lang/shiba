//
//  DiagnosticConsumer.swift
//  Shiba
//
//  Created by Khoa Le on 03/12/2020.
//

import Foundation

// MARK: - DiagnosticConsumer

public protocol DiagnosticConsumer: AnyObject {
  func consume(_ diagnostic: Diagnostic)
}

// MARK: - StreamConsumer

public class StreamConsumer: DiagnosticConsumer {

  public func consume(_ diagnostic: Diagnostic) {

  }


}
