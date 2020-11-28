//
//  Token.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

struct Token {
	let kind: TokenKind
	let range: SourceRange

	var isKeyword: Bool {
		return kind.isKeyword
	}

	var isLiteral: Bool {
		return kind.isLiteral
	}

	var isLineSeparator: Bool {
		return kind.isLineSeparator
	}

	var isString: Bool {
		return kind.isString
	}

	var isEOF: Bool {
		return kind.isEOF
	}
}
