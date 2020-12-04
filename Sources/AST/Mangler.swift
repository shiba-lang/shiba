//
//  Mangler.swift
//  Shiba
//
//  Created by Khoa Le on 02/12/2020.
//

import Foundation

public enum Mangler {
  public static func mangle(_ c: ClosureExpr, in d: FuncDeclExpr) -> String {
    "_WC" + mangle(d, isRoot: false)
  }

  public static func mangle(_ d: FuncDeclExpr, isRoot: Bool = true) -> String {
    if d.has(attribute: .foreign) {
      return d.name.name
    }
    var str = isRoot ? "_WF" : ""
    if case .deinitializer(let type) = d.kind {
      str += "D" + mangle(type, isRoot: false)
    } else {
      switch d.kind {
      case .initializer(let type):
        str += "I" + mangle(type, isRoot: false)
      case .method(let type):
        str += "M" + mangle(type, isRoot: false)
        str += d.name.name.withCount
      default:
        str += d.name.name.withCount
      }
      for arg in d.args where !arg.isImplicitSelf {
        if let external = arg.externalName {
          if external == arg.name {
            str += "S"
          } else {
            str += "E"
            str += external.name.withCount
          }
        }
        str += arg.name.name.withCount
        str += mangle(arg.type, isRoot: false)
      }
      str += "_"
      let returnType = d.returnType.type ?? .void
      if returnType != .void {
        str += "R" + mangle(returnType, isRoot: false)
      }
    }
    return str
  }

  public static func mangle(_ t: DataType, isRoot: Bool = true) -> String {
    var str = isRoot ? "_WT" : ""
    switch t {
    case .function(let args, let returnType):
      str += "F"
      for arg in args {
        str += mangle(arg, isRoot: false)
      }
      str += "R" + mangle(returnType, isRoot: false)
    case .tuple(let fields):
      str += "t"
      for field in fields {
        str += mangle(field, isRoot: false)
      }
      str += "T"
    case .int(let width, _):
      str += "s"
      if width == 64 {
        str += "I"
      } else {
        str += "i\(width)"
      }
    case .floating(let type):
      str += "s"
      switch type {
      case .float:
        str += "f"
      case .double:
        str += "d"
      case .float80:
        str += "F"
      }
    case .bool:
      str += "sb"
    case .void:
      str += "sv"
    case .pointer:
      let level = t.pointerLevel()
      if level > 0 {
        str += "P\(level)T"
        str += mangle(t.rootType, isRoot: false)
      }
    default:
      str += t.description.withCount
    }
    return str
  }
}
