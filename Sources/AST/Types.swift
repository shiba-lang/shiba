//
//  TypeExprs.swift
//  Shiba
//
//  Created by Khoa Le on 28/11/2020.
//

import Foundation

// MARK: - FloatingPointType

public enum FloatingPointType {
  case float
  case double
  case float80
}

// MARK: - DataType

public enum DataType: CustomStringConvertible, Hashable {
  case int(width: Int, signed: Bool)
  case floating(type: FloatingPointType)
  case bool
  case void
  case custom(name: String)
  case any

  indirect case function(args: [DataType], returnType: DataType)
  indirect case pointer(type: DataType)
  indirect case tuple(fields: [DataType])

  // MARK: Lifecycle

  init(name: String) {
    switch name {
    case "Int8": self = .int8
    case "Int16": self = .int16
    case "Int32": self = .int32
    case "Int": self = .int64
    case "Bool": self = .bool
    case "Void": self = .void
    case "Float": self = .float
    case "Float80": self = .float80
    case "Double": self = .double
    case "Any": self = .any
    default: self = .custom(name: name)
    }
  }

  // MARK: Public

  public static let int64: DataType = .int(width: 64, signed: true)
  public static let int32: DataType = .int(width: 32, signed: true)
  public static let int16: DataType = .int(width: 16, signed: true)
  public static let int8: DataType = .int(width: 8, signed: true)
  public static let uint64: DataType = .int(width: 64, signed: false)
  public static let uint32: DataType = .int(width: 32, signed: false)
  public static let uint16: DataType = .int(width: 16, signed: false)
  public static let uint8: DataType = .int(width: 8, signed: false)
  public static let float: DataType = .floating(type: .float)
  public static let double: DataType = .floating(type: .double)
  public static let float80: DataType = .floating(type: .float80)

  public var description: String {
    switch self {
    case .int(width: 64, let signed):
      return "\(signed ? "" : "U")Int"
    case let .int(width, signed):
      return "\(signed ? "" : "U")Int\(width)"
    case .bool: return "Bool"
    case .void: return "Void"
    case let .custom(name): return name
    case let .pointer(type):
      return "*\(type)"
    case let .floating(type):
      switch type {
      case .float: return "Float"
      case .double: return "Double"
      case .float80: return "Float80"
      }
    case let .tuple(fields):
      let fields = fields.map { $0.description }
        .joined(separator: ", ")
      return "(\(fields))"
    case let .function(args, returnType):
      let args = args.map { $0.description }
        .joined(separator: ", ")
      return "(\(args) -> \(returnType)"
    case .any: return "Any"
    }
  }

  public static func ==(lhs: DataType, rhs: DataType) -> Bool {
    switch (lhs, rhs) {
    case (.int(let lhsWidth, let lhsSigned), .int(let rhsWidth, let rhsSigned)):
      return lhsWidth == rhsWidth && lhsSigned == rhsSigned
    case (.bool, .bool):
      return true
    case (.void, .void):
      return true
    case (.pointer(let lhsType), .pointer(type: let rhsType)):
      return lhsType == rhsType
    case (.any, .any):
      return true
    case (.floating(let lhsDouble), .floating(let rhsDouble)):
      return lhsDouble == rhsDouble
    case (.function(let lhsArgs, let lhsRet), .function(let rhsArgs, let rhsRet)):
      return lhsArgs == rhsArgs && lhsRet == rhsRet
    case (.tuple(let lhsFields), .tuple(let rhsFields)):
      return lhsFields == rhsFields
    case (.custom(let lhsName), .custom(let rhsName)):
      return lhsName == rhsName
    default: return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(description)
    hasher.combine(0x01a13f61)
  }

  // MARK: Internal

  var isPointer: Bool {
    if case .pointer = self { return true }
    return false
  }

  func pointerLevel() -> Int {
    guard case let .pointer(t) = self else {
      return 0
    }
    return t.pointerLevel() + 1
  }

}
