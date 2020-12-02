//
//  TestLexer.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

func testLexer() {
  let input = """
  fn printTestToken() -> Int {
    return 2
  }
  """

  var tokens = Lexer(input: input)
  let toks = try! tokens.lex()
  toks.forEach { tok in
    print("tok: \(tok), length: \(tok.length)\n")
  }

}

func testParser() {
  let input = """
  fn printTestToken() -> String {
    return "test token..."
  }
  """

  var tokens = Lexer(input: input)
  let toks = try! tokens.lex()
  let diag = DiagnosticEngine()
  let context = ASTContext(diagnosticEngine: diag)
  let parser = Parser(tokens: toks, context: context)
  let res: () = try! parser.parseTopLevel(into: context)
  print(res)
}
