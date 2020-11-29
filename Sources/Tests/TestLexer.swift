//
//  TestLexer.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

func testLexer() {
  let input = """
  fn printTestToken() -> String {
    return "test token..."
  }
  """

  var tokens = Lexer(input: input)
  let toks = try! tokens.lex()
  toks.forEach { tok in
    print("tok: \(tok), length: \(tok.length)\n")
  }

}
