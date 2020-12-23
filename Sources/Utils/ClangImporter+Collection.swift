//
//  ClangImporter+Collection.swift
//  Shiba
//
//  Created by Khoa Le on 09/12/2020.
//

import Foundation

//extension Collection where Iterator.Element == String {
//	func withCArrayOfCStrings<Result>(_ f: (UnsafeMutablePointer<UnsafePointer<Int8>?>) throws -> Result) rethrows -> Result {
//		let ptr = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: self.count)
//		defer {
//			freelist(ptr, count: self.count)
//		}
//
//		for (idx, str) in enumerated() {
//			str.withCString { (cStr) in
//				ptr[idx] = strdup(cStr)
//			}
//		}
//
//		return try f(unsafeBitCast(ptr, to: UnsafeMutablePointer<UnsafePointer<Int8>?>.self))
//	}
//}
//
//fileprivate func freelist<T>(_ ptr: UnsafeMutablePointer<UnsafeMutablePointer<T>?>, count: Int) {
//	for i in 0..<count {
//		free(ptr[i])
//	}
//	free(ptr)
//}
//
//extension CXString {
//	func asSwift() -> String {
//		defer {
//			clang_disposeString(self)
//		}
//
//		let str = String(cString: clang_getCString(self))
//		let components = str.components(separatedBy: " ")
//		return components.last ?? str
//	}
//}
