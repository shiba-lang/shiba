//
//  main.swift
//  Shiba
//
//  Created by Khoa Le on 25/11/2020.
//

import Foundation

// MARK: - StandardTextOutputStream

class StandardTextOutputStream: TextOutputStream {
  func write(_ string: String) {
    let stdout = FileHandle.standardOutput
    stdout.write(string.data(using: .utf8)!)
  }
}

// MARK: - StandardErrorTextOutputStream

class StandardErrorTextOutputStream: TextOutputStream {
  func write(_ string: String) {
    let stderr = FileHandle.standardError
    stderr.write(string.data(using: .utf8)!)
  }
}

fileprivate var stdout = StandardTextOutputStream()

func populate(
  driver: Driver,
  options: Options,
  context: ASTContext,
  input: String
) {
  driver.add("lexing and parsing") { context in
    var lexer = Lexer(input: input)
    let tokens = try lexer.lex()
    let parser = Parser(
      tokens: tokens,
      context: context,
      filename: options.filename
    )
    try parser.parseTopLevel(into: context)
  }

  if options.importC {
    //		driver.add(pass: ClangImporter.self)
  }

  switch options.mode {
  case .emitAST:
    driver.add("Dumping the AST") { context in
      ASTDumper(stream: &stdout, context: context)
        .run(in: context)
    }
    return
  case .prettyPrint:
    driver.add("Pretty Printing the AST") { context in
      ASTPrinter(stream: &stdout, context: context)
        .run(in: context)
    }
    return
  }
}

// MARK: - Mode

enum Mode: Int {
  case emitAST
  case prettyPrint

  // MARK: Lifecycle

  init(_ raw: RawMode) {
    switch raw {
    case EmitAST:
      self = .emitAST
    case PrettyPrint:
      self = .prettyPrint
    default:
      fatalError("invalid mode \(raw)")
    }
  }
}

// MARK: - Options

struct Options {

  // MARK: Lifecycle

  init(_ raw: RawOptions) {
    filename = String(cString: raw.filename!)
    mode = Mode(raw.mode)
    var strs = [String]()
    for i in 0..<raw.argCount {
      strs.append(String(cString: raw.remainingArgs[i]!))
    }
    remainder = strs
    importC = raw.importC
    DestroyRawOptions(raw)
  }

  // MARK: Internal

  let filename: String
  let mode: Mode
  let remainder: [String]
  let importC: Bool

}

func main() -> Int32 {
  let options = Options(ParseArguments(CommandLine.argc, CommandLine.unsafeArgv))
  var input = ""

  if options.filename == "<stdin>" {
    while let line = readLine() {
      input += line + "\n"
    }
  } else if let str = try? String(contentsOfFile: options.filename) {
    input = str
  } else {
    fatalError("Error: unknown file \(options.filename)")
  }

  let diag = DiagnosticEngine()
  let context = ASTContext(filename: options.filename, diagnosticEngine: diag)
  let driver = Driver(context: context)

  populate(driver: driver, options: options, context: context, input: input)
  driver.run(in: context)

  let isATTY = isatty(STDERR_FILENO) != 0
  var stderr = StandardErrorTextOutputStream()
  let consumer = StreamConsumer(
    filename: options.filename,
    lines: input.components(separatedBy: "\n"),
    stream: &stderr,
    isColored: isATTY
  )
  diag.register(consumer)
  diag.consumeDiagnostics()

  return diag.hasErrors ? 1 : 0
}

exit(main())
