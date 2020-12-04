//
//  AttributedStringConsumer.swift
//  Shiba
//
//  Created by Khoa Le on 04/12/2020.
//

import UIKit

final class AttributedStringConsumer: DiagnosticConsumer {

  // MARK: Lifecycle

  init(lines: [String], palette: TextAttributes) {
    self.lines = lines
    self.palette = palette
  }

  // MARK: Internal

  var lines: [String]
  var palette: TextAttributes

  var attributedString: NSAttributedString {
    NSAttributedString(attributedString: builder)
  }

  func consume(_ diagnostic: Diagnostic) {
    if let sourceLoc = diagnostic.sourceLocation {
      bold("\(sourceLoc.line):\(sourceLoc.column) ")
    }

    switch diagnostic.diagnosticType {
    case .warning:
      bold("warning: ", .yellow)
    case .error:
      bold("error: ", .red)
    }
    bold("\(diagnostic.message)\n")
    if let loc = diagnostic.sourceLocation, loc.line > 0 {
      let line = lines[loc.line - 1]
      lexString(line)
      string("\n")
      string(highlightString(forDiag: diagnostic), .green)
      string("\n")
    }
  }

  // MARK: Private

  private var builder = NSMutableAttributedString()

  private func lexString(_ s: String) {
    var lexer = Lexer(input: s)
    let str = NSMutableAttributedString(string: s)
    let stringRange = NSRange(location: 0, length: str.length)
    str.addAttribute(
      NSAttributedString.Key.font,
      value: Styles.Text.font,
      range: stringRange
    )
    str.addAttribute(
      NSAttributedString.Key.foregroundColor,
      value: palette.normal,
      range: stringRange
    )
    let tokens = try? lexer.lex()
    for token in tokens ?? [] {
      if token.isKeyword {
        str.addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: palette.keyword,
          range: token.range.nsRange
        )
      } else if token.isLiteral {
        str.addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: palette.literal,
          range: token.range.nsRange
        )
      } else if token.isString {
        str.addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: palette.string,
          range: token.range.nsRange
        )
      } else if !token.isEOF {
        str.addAttribute(
          NSAttributedString.Key.foregroundColor,
          value: palette.normal,
          range: token.range.nsRange
        )
      }
    }
    builder.append(str)
  }

  private func highlightString(forDiag diag: Diagnostic) -> String {
    guard let loc = diag.sourceLocation, loc.line > 0 && loc.column > 0 else {
      return ""
    }
    var chars = [Character]()
    if !diag.highlights.isEmpty {
      let ranges = diag.highlights.sorted {
        $0.start.charOffset < $1.start.charOffset
      }
      chars = [Character](repeating: " ", count: ranges.last!.end.column)
      for range in ranges {
        let r = (range.start.column - 1)..<(range.end.column - 1)
        let tildes = [Character](repeating: "~", count: r.count)
        chars.replaceSubrange(r, with: tildes)
      }
    }

    let index = loc.column - 1
    if index >= chars.endIndex {
      chars += [Character](
        repeating: " ",
        count: chars.distance(from: chars.endIndex, to: index)
      )
      chars.append("^")
    } else {
      chars[index] = "^" as Character
    }
    return String(chars)
  }

  private func bold(_ s: String, _ color: UIColor = .white) {
    let attrs = [
      NSAttributedString.Key.font: Styles.Text.boldFont,
      .foregroundColor: color,
    ]
    let attrString = NSAttributedString(string: s, attributes: attrs)
    builder.append(attrString)
  }

  private func string(_ s: String, _ color: UIColor = .white) {
    let attrs = [
      NSAttributedString.Key.font: Styles.Text.font,
      .foregroundColor: color,
    ]
    let attrString = NSAttributedString(string: s, attributes: attrs)
    builder.append(attrString)
  }

}
