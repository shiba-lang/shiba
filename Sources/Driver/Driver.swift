//
//  Driver.swift
//  Shiba
//
//  Created by Khoa Le on 02/12/2020.
//

import Foundation

// MARK: - Pass

public protocol Pass {
  func run(in context: ASTContext) throws
  var title: String { get }
  var context: ASTContext { get }
  init(context: ASTContext)
}

// MARK: - Driver

public class Driver: Pass {

  // MARK: Lifecycle

  public required init(context: ASTContext) {
    self.context = context
  }

  // MARK: Public

  public let context: ASTContext
  public var timings = [(String, Double)]()

  public var title: String {
    "Driver"
  }

  public func add(_ title: String, pass: @escaping (ASTContext) throws -> Void) {
    passes.append(AnyPass(title: title, function: pass, context: context))
  }

  public func run(in context: ASTContext) {
    for pass in passes {
      let start = CFAbsoluteTimeGetCurrent()
      do {
        try pass.run(in: context)
      } catch {
        context.error(error)
      }
      let end = CFAbsoluteTimeGetCurrent()
      timings.append((pass.title, end - start))
      if context.diag.hasErrors {
        break
      }
    }
  }

  // MARK: Internal

  private(set) var passes = [Pass]()
}

// MARK: - AnyPass

fileprivate struct AnyPass: Pass {

  // MARK: Lifecycle

  init(context: ASTContext) {
    fatalError("use init(title:function:context:)")
  }

  init(
    title: String,
    function: @escaping (ASTContext) throws -> Void,
    context: ASTContext
  ) {
    self.title = title
    self.context = context
    self.function = function
  }

  // MARK: Internal

  let function: (ASTContext) throws -> Void
  let title: String
  let context: ASTContext

  func run(in context: ASTContext) throws {
    try function(context)
  }
}
