//
//  Tests.swift
//  Tests
//
//  Created by Khoa Le on 08/12/2020.
//

import XCTest

//@_silgen_name("shiba_init")
//func shiba_init()

class RuntimeTests: XCTestCase {

  override class func setUp() {
    shiba_init()
  }

  func testShibaAlloc() throws {
    for _ in 0..<1000 {
      _ = shiba_alloc(MemoryLayout<Int>.size)
    }
  }

  func testStacktrace() {
    "".withCString { s in
      shiba_fatalError(s)
    }
  }

}
