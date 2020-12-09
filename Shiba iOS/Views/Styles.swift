//
//  Styles.swift
//  Shiba iOS
//
//  Created by Khoa Le on 03/12/2020.
//

import UIKit

// MARK: - Styles

enum Styles {
  enum ColorScheme {
    static let keyword = UIColor.rgb(red: 178.0, green: 24.0, blue: 137.0)
    static let literal = UIColor.rgb(red: 120.0, green: 109.0, blue: 196.0)
    static let normal = UIColor.white
    static let comment = UIColor.rgb(red: 65.0, green: 182.0, blue: 69.0)
    static let string = UIColor.rgb(red: 219.0, green: 44.0, blue: 56.0)
    static let internalName = UIColor.rgb(red: 131.0, green: 192.0, blue: 87.0)
    static let externalName = UIColor.rgb(red: 0.0, green: 160.0, blue: 190.0)
    static let warning = UIColor.rgb(red: 1.0, green: 221.0, blue: 0)
    static let error = UIColor.rgb(red: 222.0, green: 7.0, blue: 7.0)
  }

  enum Text {
    static let font = UIFont(name: "Menlo", size: 16.0)!
    static let boldFont = UIFont(name: "Menlo-bold", size: 16.0)!
  }
}

extension UIColor {
  static func rgb(
    red: CGFloat,
    green: CGFloat,
    blue: CGFloat,
    alpha: CGFloat = 1
  ) -> UIColor {
    UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
  }
}
