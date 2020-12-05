//
//  SourceAnnotator.swift
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

// MARK: - SourceAnnotator

final class SourceAnnotator: ASTTransformer {

  // MARK: Lifecycle

  init(attributes: TextAttributes, context: ASTContext) {
    self.attributes = attributes
    super.init(context: context)
  }

  required public init(context: ASTContext) {
    fatalError("init(context:) has not been implemented")
  }


  // MARK: Internal

  let attributes: TextAttributes
  var errorAttributes = [Attribute]()
  var soureAttributes = [Attribute]()

  override func visitFuncCallExpr(_ expr: FuncCallExpr) {
    super.visitFuncCallExpr(expr)
    let decl = expr.decl!
    let color: UIColor
    if case .initializer(let type) = decl.kind {
      color = self.color(for: type)
    } else {
      color = decl.sourceRange == nil ? attributes.externalName : attributes.internalName
    }

    switch expr.lhs {
    case let lhs as VarExpr:
      if let range = lhs.sourceRange?.nsRange {
        add(color: color, range: range)
      }
    case let lhs as FieldLookupExpr:
      if let range = lhs.name.range?.nsRange {
        add(color: color, range: range)
      }
    default:
      visit(expr.lhs)
    }
  }

  override func visitStringExpr(_ expr: StringExpr) {
    if let range = expr.sourceRange?.nsRange {
      add(color: attributes.string, range: range)
    }
    super.visitStringExpr(expr)
  }

  override func visitFieldLookupExpr(_ expr: FieldLookupExpr) {
    guard let decl = expr.decl else { return }
    if let range = expr.name.range?.nsRange,
       let decl = decl as? DeclExpr
    {
      let color = context.isIntrinsic(decl: decl) ? attributes.externalName : attributes.internalName
      add(color: color, range: range)
    }
    super.visitFieldLookupExpr(expr)
  }

  override func visitFuncDeclExpr(_ expr: FuncDeclExpr) {
    add(attributes(for: expr.returnType))
    super.visitFuncDeclExpr(expr)
  }

  override func visitFuncArgumentAssignExpr(_ expr: FuncArgumentAssignExpr) {
    add(attributes(for: expr.typeRef!))
    super.visitFuncArgumentAssignExpr(expr)
  }

  override func visitVarAssignExpr(_ expr: VarAssignExpr) {
    add(attributes(for: expr.typeRef!))
    super.visitVarAssignExpr(expr)
  }

  override func visitExtensionExpr(_ expr: ExtensionExpr) {
    add(attributes(for: expr.typeRef))
    super.visitExtensionExpr(expr)
  }

  override func visitTypeDeclExpr(_ expr: TypeDeclExpr) {
    let ref = TypeRefExpr(type: expr.type, name: expr.name)
    add(attributes(for: ref))
    super.visitTypeDeclExpr(expr)
  }

  override func visitTypeAliasExpr(_ expr: TypeAliasExpr) {
    add(attributes(for: expr.bound))
    super.visitTypeAliasExpr(expr)
  }

  override func visitClosureExpr(_ expr: ClosureExpr) {
    add(attributes(for: expr.returnType))
    super.visitClosureExpr(expr)
  }

  // MARK: Private

  private func attributes(for typeRef: TypeRefExpr) -> [Attribute] {
    var attrs = [Attribute]()
    if let funcRef = typeRef as? FuncTypeRefExpr {
      for type in funcRef.argNames {
        attrs += attributes(for: type)
      }
      attrs += attributes(for: funcRef.retName)
    } else if let pointerRef = typeRef as? PointerTypeRefExpr {
      attrs += attributes(for: pointerRef.pointed)
    } else if let tupleRef = typeRef as? TupleTypeRefExpr {
      for type in tupleRef.fieldNames {
        attrs += attributes(for: type)
      }
    } else {
      if let type = typeRef.type,
         let range = typeRef.sourceRange?.nsRange
      {
        let color = self.color(for: type)
        let attr = Attribute(
          name: NSAttributedString.Key.foregroundColor.rawValue,
          value: color,
          range: range
        )
        attrs.append(attr)
      }
    }
    return attrs
  }

  private func add(color: UIColor, range: NSRange) {
    let attr = Attribute(
      name: NSAttributedString.Key.foregroundColor.rawValue,
      value: color,
      range: range
    )
    soureAttributes.append(attr)
  }

  private func add(_ attributes: [Attribute]) {
    soureAttributes.append(contentsOf: attributes)
  }

  private func color(for type: DataType) -> UIColor {
    context.isIntrinsic(type: type) ? attributes.externalName : attributes.internalName
  }

}

// MARK: DiagnosticConsumer

extension SourceAnnotator: DiagnosticConsumer {
  func consume(_ diagnostic: Diagnostic) {
    for r in diagnostic.highlights {
      let range = r.nsRange
      let color = diagnostic.diagnosticType == .warning
        ? Styles.ColorScheme.warning
        : Styles.ColorScheme.error
      let style = NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue
      errorAttributes.append(Attribute(
        name: NSAttributedString.Key.underlineColor.rawValue,
        value: style,
        range: range
      ))
      errorAttributes.append(Attribute(
        name: NSAttributedString.Key.underlineColor.rawValue,
        value: color,
        range: range
      ))
    }
  }
}
