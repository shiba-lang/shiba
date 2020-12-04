//
//  Token.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

public struct Token {

  // MARK: Public

  public var length: Int {
    range.end.charOffset - range.start.charOffset
  }

  public var isKeyword: Bool {
    kind.isKeyword
  }

  public var isLiteral: Bool {
    kind.isLiteral
  }

  public var isLineSeparator: Bool {
    kind.isLineSeparator
  }

  public var isString: Bool {
    kind.isString
  }

  public var isEOF: Bool {
    kind.isEOF
  }

  // MARK: Internal

  let kind: TokenKind
  let range: SourceRange

}
