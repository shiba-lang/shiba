//
//  TextAttribute.swift
//  Shiba
//
//  Created by Khoa Le on 03/12/2020.
//

#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif


// MARK: - TextAttributes

struct TextAttributes {
  let font: UIFont
  let boldFont: UIFont
  let keyword: UIColor
  let literal: UIColor
  let normal: UIColor
  let comment: UIColor
  let string: UIColor
  let internalName: UIColor
  let externalName: UIColor
}

// MARK: - Attribute

struct Attribute {
  let name: String
  let value: Any
  let range: NSRange
}
