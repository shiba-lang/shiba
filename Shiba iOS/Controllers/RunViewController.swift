//
//  RunViewController.swift
//  Shiba iOS
//
//  Created by Khoa Le on 04/12/2020.
//

import UIKit

final class RunViewController: UIViewController {

  // MARK: Internal

  @IBOutlet weak var textView: UITextView!

  weak var driver: Driver!
  var consumer: AttributedStringConsumer!
  var hasRun: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()

    textView.textContainerInset = .init(top: 15, left: 15, bottom: 15, right: 15)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if hasRun { return }
    hasRun = true
    DispatchQueue.global(qos: .default).async {
      self.driver.run(in: self.driver.context)
      self.driver.context.diag.consumeDiagnostics()

      if self.driver.context.diag.hasErrors {
        DispatchQueue.main.async {
          self.textView.attributedText = self.consumer.attributedString
        }
      }
    }
  }

  // MARK: Private


  @IBAction
  private func didTappedDoneButton(_ sender: Any) {
    dismiss(animated: true)
  }
}
