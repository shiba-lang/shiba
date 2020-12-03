//
//  InputViewController.swift
//  Shiba iOS
//
//  Created by Khoa Le on 03/12/2020.
//

import UIKit

// MARK: - InputViewController

final class InputViewController: UIViewController {

  // MARK: Internal

  @IBOutlet weak var textView: UITextView!
  var document: SourceDocument!
  var storage: LexerTextStorage!

  let colorScheme = TextAttributes(
    font: Styles.Text.font!,
    boldFont: Styles.Text.boldFont!,
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

    storage = LexerTextStorage(
      attributes: colorScheme,
      filename: document.fileName
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

  // MARK: Private

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
