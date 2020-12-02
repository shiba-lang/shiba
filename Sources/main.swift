//
//  main.swift
//  Shiba
//
//  Created by Khoa Le on 25/11/2020.
//

import Foundation

func populate(driver: Driver, context: ASTContext, input: String) {
  driver.add("lexing and parsing") { context in
    var lexer = Lexer(input: input)
    let tokens = try lexer.lex()
    let parser = Parser(tokens: tokens, context: context)
    try parser.parseTopLevel(into: context)
  }
}

func main() -> Int32 {
  let diag = DiagnosticEngine()
  let context = ASTContext(diagnosticEngine: diag)
  let driver = Driver(context: context)

  let input = ""
  populate(driver: driver, context: context, input: input)
  driver.run(in: context)
  return diag.hasErrors ? 1 : 0
}

exit(main())
