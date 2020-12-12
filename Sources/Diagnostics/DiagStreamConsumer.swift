//
//  DiagStreamConsumer.swift
//  Shiba
//
//  Created by Khoa Le on 06/12/2020.
//

import Foundation

// MARK: - StreamConsumer

public class StreamConsumer<StreamType: TextOutputStream>: DiagnosticConsumer {

  var lines: [String]
  var filename: String
  var isColored: Bool
  var stream: StreamType

  public init(
    filename: String,
    lines: [String],
    stream: inout StreamType,
    isColored: Bool
  ) {
    let url = URL(fileURLWithPath: filename)
    self.filename = url.lastPathComponent
    self.isColored = isColored
    self.lines = lines
    self.stream = stream
  }

  private func with(_ colors: [ANSIColor], block: () -> Void) {
    if isColored {
      colors.forEach {
        stream.write($0.rawValue)
      }
    }
    block()
    if isColored {
      stream.write(ANSIColor.reset.rawValue)
    }
  }

  private func highlightString(forDiag diag: Diagnostic) -> String {
    guard let loc = diag.sourceLocation, loc.line > 0 && loc.column > 0 else {
      return ""
    }
    var chars = [Character]()
    if !diag.highlights.isEmpty {
      let ranges = diag.highlights
        .filter {
          $0.start.line == loc.line && $0.end.line == loc.line
        }
        .sorted {
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

  public func consume(_ diagnostic: Diagnostic) {
    stream.write("\(filename):")
    if let sourceLoc = diagnostic.sourceLocation {
      with([.bold]) {
        stream.write("\(sourceLoc.line):\(sourceLoc.column)")
      }
    }
    stream.write(" ")
    switch diagnostic.diagnosticType {
    case .error:
      with([.bold, .red]) {
        stream.write("error: ")
      }
    case .warning:
      with([.bold, .green]) {
        stream.write("warning: ")
      }
    }
    with([.bold]) {
      stream.write("\(diagnostic.message)\n")
    }
    if let loc = diagnostic.sourceLocation, loc.line > 0 {
      let line = lines[loc.line - 1]
      stream.write(line + "\n")
      with([.bold, .magenta]) {
        stream.write(highlightString(forDiag: diagnostic))
      }
      stream.write("\n")
    }

  }


}
