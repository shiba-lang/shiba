//
//  Token.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

struct Token {
  let kind: TokenKind
  let range: SourceRange

  var length: Int {
    range.end.charOffset - range.start.charOffset
  }

  var isKeyword: Bool {
    kind.isKeyword
  }

  var isLiteral: Bool {
    kind.isLiteral
  }

  var isLineSeparator: Bool {
    kind.isLineSeparator
  }

  var isString: Bool {
    kind.isString
  }

  var isEOF: Bool {
    kind.isEOF
  }
}
