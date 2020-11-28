//
//  TestLexer.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

func testLexer() {
  let input = """
  // just simple thing
  /*
  hmmmm it work?
  this is test for multi line comment
  */
  fn test() -> String {
  	return "test something"
  }
  """

  let tokens = try! Lexer(input: input).lex()
  tokens.forEach { tok in
    print("\(tok) \n")
  }

}
