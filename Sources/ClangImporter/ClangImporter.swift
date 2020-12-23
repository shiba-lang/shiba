//
//  ClangImporter.swift
//  Shiba
//
//  Created by Khoa Le on 07/12/2020.
//

import Foundation

//extension CXErrorCode: Error, CustomStringConvertible {
//	public var description: String {
//		switch self {
//		case CXError_Success:
//			return "CXErrorCode.success"
//		case CXError_Crashed:
//			return "CXErrorCode.crashed"
//		case CXError_Failure:
//			return "CXErrorCode.failure"
//		case CXError_ASTReadError:
//			return "CXErrorCode.astReadError"
//		case CXError_InvalidArguments:
//			return "CXErrorCode.invalidArguments"
//		default:
//			fatalError("unknown CXErrorCode: \(self.rawValue)")
//		}
//	}
//}
//
//enum ImportError: Error {
//	case pastIntMax
//}
//
//extension CXCursor {
//	var isInvalid: Bool {
//		switch self.kind {
//		case CXCursor_InvalidCode,
//				 CXCursor_InvalidFile,
//				 CXCursor_LastInvalid,
//				 CXCursor_FirstInvalid,
//				 CXCursor_NotImplemented,
//				 CXCursor_NoDeclFound:
//			return true
//		default:
//			return false
//		}
//	}
//
//	var isValid: Bool {
//		return !self.isInvalid
//	}
//}
//
//public final class ClangImporter: Pass {
//
//	static let headerFiles = [
//		"stdlib.h",
//		"stdio.h",
//		"stdint.h",
//		"stddef.h",
//		"math.h",
//		"string.h",
//		"_types.h",
//		"pthread.h"
//	]
//
//	// TODO: - Stop using absolute Xcode paths
//	#if os(macOS)
//	static let paths = headerFiles.map {
//		"/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include" + $0
//	} + ["/usr/local/include/shiba/shiba.h"]
//	#else
//	static let paths = headerFiles.map {
//		"/usr/local/include/" + $0
//	} + ["/usr/local/include/shiba/shiba.h"]
//	#endif
//
//	public var context: ASTContext
//	public var title: String {
//		return "Clang Importer"
//	}
//
//	var importedTypes = [Identifier: TypeDeclExpr]()
//	var importedFunctions = [Identifier: FuncDeclExpr]()
//
//	required public init(context: ASTContext) {
//		self.context = context
//	}
//
//	func translationUnit(for path: String) throws -> CXTranslationUnit {
//		let index = clang_createIndex(0, 0)
//		var args = [
//			"-c",
//			"-I/usr/include",
//			"-I/usr/local/include",
//			"~/code/llvm-project/llvm/include"
//		]
//
//		#if os(macOS)
//		args.append("-I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/")
//		#endif
//		defer {
//			clang_disposeIndex(index)
//		}
//
//		let flags = [
//			CXTranslationUnit_SkipFunctionBodies,
//			CXTranslationUnit_DetailedPreprocessingRecord
//		].reduce(0 as UInt32) {
//			$0 | $1.rawValue
//		}
//
//		return try args.withCArrayOfCStrings { (ptr) in
//			var tu: CXTranslationUnit? = nil
//			let err = clang_parseTranslationUnit2(index, path, ptr, 1, nil, 0, flags, &tu)
//			guard err == CXError_Success else {
//				throw err
//			}
//
//			guard let _tu = tu else {
//				throw CXError_Failure
//			}
//			return _tu
//		}
//
//	}
//
//	private func makeAlias(name: String, type: DataType) -> TypeAliasExpr {
//		return TypeAliasExpr(name: Identifier(name: name), bound: type.ref())
//	}
//
//	private func synthesize(name: String, args: [DataType], ret: DataType, hasVarArgs: Bool, attributes: [DeclAccessKind]) -> FuncDeclExpr {
//		let args = args.map {
//			FuncArgumentAssignExpr(name: "", type: $0.ref())
//		}
//		return FuncDeclExpr(name: Identifier(name: name), returnType: ret.ref(), args: args, attributes: attributes, hasVarArgs: hasVarArgs)
//	}
//
//	public func run(in context: ASTContext) throws {
//		self.context.add(makeAlias(name: "uint16_t", type: .int16))
//		self.context.add(makeAlias(name: "__builtin_va_list", type: .pointer(type: .int8)))
//		self.context.add(makeAlias(name: "__darwin_pthread_handler_rec", type: .pointer(type: .int8)))
//		self.context.add(synthesize(name: "shiba_fatalError", args: [.pointer(type: .int8)], ret: .void, hasVarArgs: false, attributes: [.foreign, .noreturn]))
//
//		for path in ClangImporter.paths {
//			do {
//				let tu = try translationUnit(for: path)
//				let cursor = clang_getTranslationUnitCursor(tu)
//				clang_visitChildrenWithBlock(cursor) { (child, parent) in
//					let kind = clang_getCursorKind(child)
//					switch kind {
//					case CXCursor_TypedefDecl:
//						self.importTypeDef(child)
//					case CXCursor_EnumDecl:
//						self.importEnum(child)
//					case CXCursor_StructDecl:
//						self.importStruct(child)
//					case CXCursor_FunctionDecl:
//						self.importFunction(child)
//					case CXCursor_MacroDefinition:
//						self.importMacro(child, in: tu)
//					default:
//						break
//					}
//					return CXChildVisit_Continue
//				}
//			} catch let err as NSError {
//				fatalError("Error loading \(path): \(err)")
//			}
//		}
//	}
//
//	private func importMacro(_ cursor: CXCursor, in tu: CXTranslationUnit) {
//		let range = clang_getCursorExtent(cursor)
//		var tokenCount: UInt32 = 0
//		var _tokens: UnsafeMutablePointer<CXToken>?
//		clang_tokenize(tu, range, &_tokens, &tokenCount)
//
//		guard let tokens = _tokens, tokenCount > 2 else { return }
//
//		defer {
//			clang_disposeTokens(tu, tokens, tokenCount)
//		}
//
//		let cursors = UnsafeMutablePointer<CXCursor>.allocate(capacity: Int(tokenCount))
//
//		defer {
//			free(cursors)
//		}
//
//		clang_annotateTokens(tu, tokens, tokenCount, cursors)
//
//		let name = clang_getTokenSpelling(tu, tokens[0]).asSwift()
//		guard context.global(named: name) == nil,
//					clang_getTokenKind(tokens[1]) == CXToken_Literal,
//					let assign = parse(tu: tu, token: tokens[1], name: name) else { return }
//		context.add(assign)
//	}
//
//	private func parse(tu: CXTranslationUnit, token: CXToken, name: String) -> VarAssignExpr? {
//		do {
//			let tok = clang_getTokenSpelling(tu, token).asSwift()
//			guard let token = try simpleParseCToken(tok) else { return nil }
//			var expr: ValExpr! = nil
//			switch token {
//			case .char(let value):
//				expr = CharExpr(value: value)
//			case .stringLiteral(let value):
//				expr = StringExpr(value: value)
//			case .number(let value, let raw):
//				expr = NumExpr(value: value, raw: raw)
//			case .identifier(let name):
//				expr = VarExpr(name: Identifier(name: name))
//			default:
//				return nil
//			}
//			return VarAssignExpr(name: Identifier(name: name), typeRef: expr.type?.ref(), rhs: expr, isMutable: false)
//		} catch {
//			return nil
//		}
//	}
//
//	private func simpleParseCToken(_ token: String) throws -> TokenKind? {
//		var lexer = Lexer(input: token)
//		let toks = try lexer.lex()
//		guard let first = toks.first?.kind else { return nil }
//		if case .identifier(value: let name) = first {
//			return try simpleParseIntegerLiteralToken(name) ?? first
//		}
//		return first
//	}
//
//	// FIXME: Actually use Clang's lexer instead of re-implementing parts of it,
//	// poorly.
//	private func simpleParseIntegerLiteralToken(_ token: String) throws -> TokenKind? {
//		var lexer = Lexer(input: token)
//		let numStr = lexer.collectWhile { $0.isNumeric }
//		guard let num = Int64(numStr) else {
//			throw ImportError.pastIntMax
//		}
//
//		let suffix = lexer.collectWhile { $0.isIdentifier }
//		for char in suffix.lowercased() {
//			if char != "u" && char != "l" { return nil }
//		}
//		return .number(value: num, raw: numStr)
//	}
//
//	private func importFunction(_ cursor: CXCursor) {
//		let name = clang_getCursorSpelling(cursor).asSwift()
//		let existing = context.functions(named: Identifier(name: name))
//		if !existing.isEmpty { return }
//		let numArgs = clang_Cursor_getNumArguments(cursor)
//		guard numArgs != -1 else { return }
//		var attributes: [DeclAccessKind] = [.foreign]
//		if clang_isNoReturn(cursor) != 0 {
//			attributes.append(.noreturn)
//		}
//
//		let hasVarArgs = clang_Cursor_isVariadic(cursor) != 0
//		let funcType = clang_getCursorType(cursor)
//		let returnTy = clang_getResultType(funcType)
//		var args = [DataType]()
//
//		guard let shibaRetTy = convertToShibaType(returnTy) else { return }
//
//		for i in 0..<numArgs {
//			let type = clang_getArgType(funcType, UInt32(i))
//			guard let shibaType = convertToShibaType(type) else { return }
//			args.append(shibaType)
//		}
//
//		let decl = synthesize(name: name, args: args, ret: shibaRetTy, hasVarArgs: hasVarArgs, attributes: attributes)
//		importedFunctions[decl.name] = decl
//		context.add(decl)
//	}
//
//	@discardableResult
//	private func importStruct(_ cursor: CXCursor) -> TypeDeclExpr? {
//		let type = clang_getCursorType(cursor)
//		let typeName = clang_getTypeSpelling(type).asSwift()
//		let name = Identifier(name: typeName)
//		if let e = importedTypes[name] { return e }
//		var values = [VarAssignExpr]()
//		clang_visitChildrenWithBlock(cursor) { (child, parent) in
//			let fieldId = Identifier(name: clang_getCursorSpelling(child).asSwift())
//			let fieldTy = clang_getCursorType(child)
//			guard let shibaTy = self.convertToShibaType(fieldTy) else {
//				return CXChildVisit_Break
//			}
//			let expr = VarAssignExpr(name: fieldId, typeRef: shibaTy.ref(), attributes: [.foreign], isMutable: true)
//			values.append(expr)
//			return CXChildVisit_Continue
//		}
//		let expr = TypeDeclExpr(name: name, fields: values, attributes: [.foreign])
//		importedTypes[name] = expr
//		context.add(expr)
//		return expr
//	}
//
//	private func importEnum(_ cursor: CXCursor) {
//		clang_visitChildrenWithBlock(cursor) { (child, parent) in
//			let n = clang_getCursorSpelling(child).asSwift()
//			let name = Identifier(name: n)
//			let varExpr = VarAssignExpr(name: name, typeRef: DataType.int32.ref(), isMutable: false)
//			self.context.add(varExpr)
//			return CXChildVisit_Continue
//		}
//	}
//
//	@discardableResult
//	private func importTypeDef(_ cursor: CXCursor) -> TypeAliasExpr? {
//		let name = clang_getCursorSpelling(cursor).asSwift()
//		let type = clang_getTypedefDeclUnderlyingType(cursor)
//		let decl = clang_getTypeDeclaration(type)
//		var shibaType: DataType?
//		if decl.kind == CXCursor_StructDecl {
//			if let expr = importStruct(decl) {
//				shibaType = expr.type
//			} else {
//				return nil
//			}
//		} else {
//			shibaType = convertToShibaType(type)
//		}
//		guard let ty = shibaType, name != "\(ty)" else {
//			return nil
//		}
//		let alias = TypeAliasExpr(name: Identifier(name: name), bound: ty.ref())
//		self.context.add(alias)
//		return alias
//	}
//
//	private func convertToShibaType(_ type: CXType) -> DataType? {
//		switch type.kind {
//		case CXType_Void: return .void
//		case CXType_Int: return .int32
//		case CXType_Bool: return .bool
//		case CXType_Enum: return .int32
//		case CXType_Float: return .float
//		case CXType_Double: return .double
//		case CXType_LongDouble: return .float80
//		case CXType_Long: return .int64
//		case CXType_UInt: return .uint32
//		case CXType_LongLong: return .int64
//		case CXType_ULong: return .uint64
//		case CXType_ULongLong: return .uint64
//		case CXType_Short: return .int16
//		case CXType_UShort: return .uint16
//		case CXType_SChar: return .int8
//		case CXType_Char16: return .int16
//		case CXType_Char32: return .int32
//		case CXType_UChar: return .uint8
//		case CXType_WChar: return .int16
//		case CXType_ObjCSel: return .pointer(type: .int8)
//		case CXType_ObjCId: return .pointer(type: .int8)
//		case CXType_NullPtr: return .pointer(type: .int8)
//		case CXType_Unexposed: return .pointer(type: .int8)
//		case CXType_ConstantArray:
//			let underlying = clang_getArrayElementType(type)
//			guard let shibaTy = convertToShibaType(underlying) else { return nil }
//			return .pointer(type: shibaTy)
//		case CXType_Pointer:
//			let pointee = clang_getPointeeType(type)
//			// Check to see if the pointee is a function type:
//			if clang_getResultType(pointee).kind != CXType_Invalid {
//				// function pointer type.
//				guard let t = convertFunctionType(pointee) else { return nil }
//				return t
//			}
//			let shibaPointee: DataType?
//			if pointee.kind == CXType_Void {
//				shibaPointee = .int8
//			} else {
//				shibaPointee = convertToShibaType(pointee)
//			}
//			guard let p = shibaPointee else {
//				return nil
//			}
//			return .pointer(type: p)
//		case CXType_FunctionProto:
//			return convertFunctionType(type)
//		case CXType_FunctionNoProto:
//			let ret = clang_getResultType(type)
//			guard let shibaRet = convertToShibaType(ret) else { return nil }
//			return .function(args: [], returnType: shibaRet)
//		case CXType_Typedef:
//			let typeName = clang_getTypeSpelling(type).asSwift()
//			return .custom(name: typeName)
//		case CXType_Record:
//			let name = clang_getTypeSpelling(type).asSwift()
//			return .custom(name: name)
//		case CXType_ConstantArray:
//			let element = clang_getArrayElementType(type)
//			let size = clang_getNumArgTypes(type)
//			guard let shibaElementType = convertToShibaType(element) else { return nil }
//			return .tuple(fields: [DataType](repeating: shibaElementType, count: Int(size)))
//		case CXType_Invalid:
//			return nil
//		default:
//			return nil
//		}
//	}
//
//	private func convertFunctionType(_ type: CXType) -> DataType? {
//		let ret = clang_getResultType(type)
//		let shibaRet = convertToShibaType(ret) ?? .void
//		let numArgs = clang_getNumArgTypes(type)
//		guard numArgs != -1 else { return nil }
//		var args = [DataType]()
//		for i in 0..<UInt32(numArgs) {
//			let type = clang_getArgType(type, UInt32(i))
//			guard let shibaArgTy = convertToShibaType(type) else { return nil }
//			args.append(shibaArgTy)
//		}
//		return .function(args: args, returnType: shibaRet)
//	}
//
//}
