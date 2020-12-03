//
//  ViewController.swift
//  Shiba iOS
//
//  Created by Khoa Le on 02/12/2020.
//

import UIKit

// MARK: - DocumentController

final class DocumentController: UIViewController {

  // MARK: Internal

  static let documentsDir = NSSearchPathForDirectoriesInDomains(
    .documentDirectory,
    .userDomainMask,
    true
  )[0]

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.dataSource = self
    tableView.delegate = self
    attempt(loadDocuments)

  }

  @IBAction
  func didTappedNewDocument(_ sender: Any) {
    let alert = UIAlertController(
      title: "New Document",
      message: "Enter a title",
      preferredStyle: .alert
    )
    alert.addTextField {
      $0.placeholder = "file.shiba"
    }
    let addAction = UIAlertAction(title: "Add", style: .default) { [weak alert] _ in
      guard let title = alert?.textFields?.first?.text else { return }
      var document: SourceDocument? = nil
      self.attempt {
        document = self.document(title: title)
      }
      guard let doc = document else { return }
      self.documents.append(doc)
      self.tableView.reloadData()
    }
    let cancleAction = UIAlertAction(title: "Cancel", style: .cancel)
    alert.addAction(addAction)
    alert.addAction(cancleAction)
    present(alert, animated: true)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowInput" {
      let destination = segue.destination as? InputViewController
      destination?.document = sender as? SourceDocument
      destination?.title = destination?.document.fileName
    }
  }

  // MARK: Private

  @IBOutlet private weak var tableView: UITableView!
  private var filePath = URL(fileURLWithPath: DocumentController.documentsDir)
  private var documents = [SourceDocument]()
  private var fileManager = FileManager.default

  private func document(title: String) -> SourceDocument {
    var url = filePath.appendingPathComponent(title)
    if url.pathExtension != "shiba" {
      url.deletePathExtension()
      url.appendPathExtension("shiba")
    }
    return SourceDocument(fileURL: url)
  }

  private func loadDocuments() throws {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(atPath: filePath.path) else { return }
    enumerator.forEach { item in
      guard let url = item as? String else { return }
      let path = filePath.appendingPathComponent(url)
      documents.append(SourceDocument(fileURL: path))
    }
  }

  private func attempt(_ f: () throws -> Void) {
    do {
      try f()
    } catch let err as NSError {
      show(error: err)
    }
  }

}

// MARK: UITableViewDataSource, UITableViewDelegate

extension DocumentController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    documents.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "DocumentCell",
      for: indexPath
    )
    let document = documents[indexPath.row]
    cell.textLabel?.text = document.fileName
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    50
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let document = documents[indexPath.row]
    let completionHandler: (String) -> (Bool) -> Void = { message in
      { success in
        if success {
          self.performSegue(withIdentifier: "ShowInput", sender: document)
        } else {
          self.showError("Failed to \(message) '\(document.fileName)")
        }
      }
    }
    let path = document.fileURL.path
    if fileManager.fileExists(atPath: path) {
      document.open(completionHandler: completionHandler("open"))
    } else {
      document.save(
        to: document.fileURL,
        for: .forCreating,
        completionHandler: completionHandler("create")
      )
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  func tableView(
    _ tableView: UITableView,
    commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    switch editingStyle {
    case .delete:
      let document = documents[indexPath.row]
      attempt {
        try fileManager.removeItem(at: document.fileURL)
        documents.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .bottom)
      }
    default: break
    }
  }
}

extension UIViewController {
  func showError(_ message: String) {
    let alert = UIAlertController(
      title: "Error",
      message: message,
      preferredStyle: .alert
    )
    let action = UIAlertAction(title: "Okay", style: .default)
    alert.addAction(action)
    present(alert, animated: true)
  }

  func show(error: NSError) {
    let alert = UIAlertController(
      title: error.localizedDescription,
      message: error.localizedFailureReason ?? "",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Ok", style: .default))
    present(alert, animated: true)
  }
}
