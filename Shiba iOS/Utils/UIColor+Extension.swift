//
//  UIColor+Extension.swift
//  Shiba
//
//  Created by Khoa Le on 03/12/2020.
//

import Foundation
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

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
