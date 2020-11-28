//
//  TestLexer.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

func testLexer() {
	let input = """
	fn test() -> String {
		return "test something"
	}
	"""

	let tokens = try! Lexer(input: input).lex()
	print("\(tokens.description)")
}
