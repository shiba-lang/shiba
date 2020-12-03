//
//  LexerTextStorage.swift
//  Shiba iOS
//
//  Created by Khoa Le on 03/12/2020.
//

import UIKit

// MARK: - LexerTextStorage

final class LexerTextStorage: NSTextStorage {

  // MARK: Lifecycle

  init(attributes: TextAttributes, filename: String, string: String = "") {
    self.attributes = attributes
    self.filename = filename
    storage = NSMutableAttributedString(string: string)
    super.init()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  let attributes: TextAttributes
  let filename: String
  let storage: NSMutableAttributedString

  override var string: String {
    storage.string
  }

  override func append(_ attrString: NSAttributedString) {
    beginEditing()
    let loc = storage.length
    storage.append(attrString)
    let range = NSRange(location: loc, length: 0)
    edited(.editedCharacters, range: range, changeInLength: attrString.length)
    endEditing()
  }

  override func attributes(
    at location: Int,
    effectiveRange range: NSRangePointer?
  ) -> [NSAttributedString.Key : Any] {
    storage.attributes(at: location, effectiveRange: range)
  }

  override func setAttributes(
    _ attrs: [NSAttributedString.Key : Any]?,
    range: NSRange
  ) {
    beginEditing()
    storage.setAttributes(attrs, range: range)
    edited(.editedAttributes, range: range, changeInLength: 0)
    endEditing()
  }

  override func replaceCharacters(in range: NSRange, with str: String) {
    replaceCharacters(in: range, with: NSAttributedString(string: str))
  }

  override func replaceCharacters(
    in range: NSRange,
    with attrString: NSAttributedString
  ) {
    beginEditing()
    storage.replaceCharacters(in: range, with: attrString.string)
    edited(
      .editedCharacters,
      range: range,
      changeInLength: attrString.length - range.length
    )
    endEditing()
  }

  override func processEditing() {
    var lexer = Lexer(input: string)
    guard let tokens = try? lexer.lex() else { return }
    let fullRange =  NSRange(location: 0, length: storage.length)
    addAttribute(
      NSAttributedString.Key.font,
      value: attributes.font,
      range: fullRange
    )
    addAttribute(
      NSAttributedString.Key.foregroundColor,
      value: attributes.normal,
      range: fullRange
    )
    for token in tokens {
      print(token)
      if token.isKeyword {
        addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: attributes.keyword,
          range: token.range.nsRange
        )
      } else if token.isLiteral {
        addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: attributes.literal,
          range: token.range.nsRange
        )
      } else if token.isString {
        addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: attributes.string,
          range: token.range.nsRange
        )
      } else if !token.isEOF {
        addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: attributes.normal,
          range: token.range.nsRange
        )
      }

    }
    super.processEditing()
  }

}

extension SourceRange {
  var nsRange: NSRange {
    let length = end.charOffset <= start.charOffset ? 0 : end.charOffset - start.charOffset
    return NSRange(location: start.charOffset, length: length)
  }
}
