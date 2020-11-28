//
//  UnicodeScalar+Extension.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

extension UnicodeScalar {
	var isNumeric: Bool {
		return isnumber(Int32(self.value)) != 0
	}

	var isSpace: Bool {
		return isspace(Int32(self.value)) != 0 && self != "\n"
	}

	var isLineSeparator: Bool {
		return self == "\n" || self == ";"
	}

	var isIdentifier: Bool {
		return isalnum(Int32(self.value)) != 0 || self == "_"
	}

	static let operatorChars: Set<UnicodeScalar> = Set("+-*/%=~<>^|&!".unicodeScalars)

	var isOperator: Bool {
		return UnicodeScalar.operatorChars.contains(self)
	}

	var isHexadecimal: Bool {
		return ishexnumber(Int32(self.value)) != 0
	}
}
