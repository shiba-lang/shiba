//
//  InputViewController.swift
//  Shiba iOS
//
//  Created by Khoa Le on 03/12/2020.
//

import UIKit

// MARK: - BlockStream

final class BlockStream: TextOutputStream {

  // MARK: Lifecycle

  init(block: @escaping (String) -> Void) {
    self.block = block
  }

  // MARK: Internal

  var block: (String) -> Void

  func write(_ string: String) {
    block(string)
  }
}

// MARK: - InputViewController

final class InputViewController: UIViewController {

  // MARK: Internal

  enum Action {
    case showAST
  }

  @IBOutlet weak var textView: UITextView!
  var document: SourceDocument!
  let colorScheme = TextAttributes(
    font: Styles.Text.font,
    boldFont: Styles.Text.boldFont,
    keyword: Styles.ColorScheme.keyword,
    literal: Styles.ColorScheme.literal,
    normal: Styles.ColorScheme.normal,
    comment: Styles.ColorScheme.comment,
    string: Styles.ColorScheme.string,
    internalName: Styles.ColorScheme.internalName,
    externalName: Styles.ColorScheme.externalName
  )

  override func viewDidLoad() {
    super.viewDidLoad()

    textView.font = colorScheme.font
    textView.textContainerInset = .init(top: 15, left: 15, bottom: 15, right: 15)
    textView.delegate = self
    textView.text = document.sourceText
    textView.addDoneButton(
      title: "Done",
      target: self,
      selector: #selector(didTappedDoneButton)
    )
    textView.autocorrectionType = .no

    storage = LexerTextStorage(
      attributes: colorScheme,
      filename: document.filename
    )
    storage.addLayoutManager(textView.layoutManager)
    storage.append(NSAttributedString(string: document.sourceText))

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardDidShow),
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    document.close { success in
      if !success {
        self.showError("Failed to save \(self.document.filename)")
      }
    }
  }

  @IBAction
  func didTappedRunButton(_ sender: Any) {
    execute(action: .showAST)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowRun" {
      guard let navController = segue.destination as? UINavigationController,
            let sender = sender as? Action,
            let destination = navController.topViewController as? RunViewController else { return }
      diagnosticEngine = DiagnosticEngine()
      context = ASTContext(
        filename: document.filename,
        diagnosticEngine: diagnosticEngine
      )
      driver = Driver(context: context)
      let text = storage.string
      let fileName = document.filename
      driver.add("lexer and parser") { context in
        var lexer = Lexer(input: text)
        do {
          let tokens = try lexer.lex()
          let parser = Parser(
            tokens: tokens,
            context: context,
            filename: fileName
          )
          try parser.parseTopLevel(into: context)
        } catch let error as Diagnostic {
          self.diagnosticEngine.add(error: error)
        } catch {
          self.diagnosticEngine.error("\(error)")
        }
      }
      driver.add(pass: Sema.self)
      driver.add(pass: TypeChecker.self)

      let block: (String) -> Void = { str in
        DispatchQueue.main.async {
          destination.textView.text += str
        }
      }

      let lines = text.components(separatedBy: "\n")
      var stream = BlockStream(block: block)

      let consumer = AttributedStringConsumer(lines: lines, palette: colorScheme)
      diagnosticEngine.register(consumer)

      destination.consumer = consumer

      if sender == .showAST {
        driver.add("Dumping the AST") { context in
          ASTDumper(stream: &stream, context: context).run(in: context)
        }
      }
      destination.driver = driver
    }

  }

  // MARK: Private

  private var storage: LexerTextStorage!
  private var diagnosticEngine = DiagnosticEngine()
  private var context: ASTContext!
  private var driver: Driver!

  private func execute(action: Action) {
    performSegue(withIdentifier: "ShowRun", sender: action)
  }

  @objc
  private func didTappedDoneButton() {
    view.endEditing(true)
  }

  @objc
  private func keyboardDidShow(notification: Notification) {
    guard let info = notification.userInfo else { return }
    let value = info[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue
    let size = value.cgRectValue.size
    let inset = UIEdgeInsets(top: 0, left: 0, bottom: size.height, right: 0)
    textView.contentInset = inset
    textView.scrollIndicatorInsets = inset
  }

  @objc
  private func keyboardWillHide() {
    textView.contentInset = .zero
    textView.scrollIndicatorInsets = .zero
  }

}

// MARK: UITextViewDelegate

extension InputViewController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    document.sourceText = storage.string
  }
}

extension UITextView {
  func addDoneButton(title: String, target: Any, selector: Selector) {

    let toolBar = UIToolbar(frame: CGRect(
      x: 0.0,
      y: 0.0,
      width: UIScreen.main.bounds.size.width,
      height: 44.0
    ))
    let flexible = UIBarButtonItem(
      barButtonSystemItem: .flexibleSpace,
      target: nil,
      action: nil
    )
    let barButton = UIBarButtonItem(
      title: title,
      style: .plain,
      target: target,
      action: selector
    )
    toolBar.setItems([flexible, barButton], animated: false)
    inputAccessoryView = toolBar
  }
}
