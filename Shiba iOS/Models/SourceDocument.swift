//
//  SourceDocument.swift
//  Shiba iOS
//
//  Created by Khoa Le on 03/12/2020.
//

import UIKit

// MARK: - DocumentError

fileprivate enum DocumentError: Error {
  case invalidSource
  case invalidContents
}

// MARK: - SourceDocument

final class SourceDocument: UIDocument {
  var fileName: String {
    fileURL.lastPathComponent
  }

  @objc var sourceText: String = "" {
    didSet {
      undoManager.registerUndo(
        withTarget: self,
        selector: #selector(getter: SourceDocument.sourceText),
        object: oldValue
      )
    }
  }
  override var fileType: String? {
    "shiba"
  }

  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    guard let data = contents as? Data,
          let string = String(data: data, encoding: .utf8) else
    {
      throw DocumentError.invalidSource
    }
    sourceText = string
  }

  override func contents(forType typeName: String) throws -> Any {
    guard let data = sourceText.data(using: .utf8) else {
      throw DocumentError.invalidContents
    }
    return data
  }
}
