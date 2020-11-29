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

  let tokens = try! Lexer(input: input).lex()
  tokens.forEach { tok in
    print("tok: \(tok), length: \(tok.length)\n")
  }

}
