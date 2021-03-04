//
//  PDFBookmarkViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.

import Foundation
import UIKit
import PDFKit

enum EditMode {
    case normal
    case editing
}

protocol PDFBookmarkViewControllerDelegate: class {
    func pdfBookmarkViewControllerDidSelect(page index: Int)
}

class PDFBookmarkViewController: UIViewController {
    
    //variables
    var currentPage: PDFPage?
    var documentName: String?
    private var status: EditMode = .normal
    var bookmarks: [String] = [String]()
    var bookmarkNames: [String] = [String]()
    weak var delegate: PDFBookmarkViewControllerDelegate?

    //outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
        
    override func viewDidLoad() {
        self.bookmarks = self.loadBookmarks()
        self.bookmarkNames = self.loadBookmarkNames()
        self.toggleAddButton()
        self.tableView.reloadData()
    }
    
    // MARK: cancel action
    @IBAction func cancelAction(_ sender: Any) {
        if self.status == .editing {
            self.disableEditing()
        }
        self.saveBookmarks()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: edit toggle action
    @IBAction func editingToogleActon(_ sender: Any) {
        if self.status == .normal {
            self.enableEditing()
        } else if  self.status == .editing {
            self.disableEditing()
        }
    }
    
    //MARK: add book mark action
    @IBAction func addBookmarkAction(_ sender: Any) {
        if let pageNumberText = self.currentPage?.label {
            self.bookmarks.append(pageNumberText)
            self.bookmarkNames.append("Page \(pageNumberText)")
            self.saveBookmarks()
            self.toggleAddButton()
            self.tableView.reloadData()
        }
    }
    
    func enableEditing() {
        self.editButton.title = NSLocalizedString("done.button.title", comment: "Done")
        self.tableView.setEditing(true, animated: true)
        self.status = .editing
    }
    
    func disableEditing() {
        self.editButton.title = NSLocalizedString("edit.button.title", comment: "Edit")
        self.tableView.setEditing(false, animated: false)
        self.status = .normal
        self.toggleAddButton()
    }
    
    //MARK: saves bookmark to user default
    func saveBookmarks() {
        UserDefaults.standard.saveBookMarks(bookmarks: self.bookmarks,
                                            documentName: self.documentName!)
        UserDefaults.standard.saveBookMarkNames(bookmarkNames: self.bookmarkNames,
                                                documentName: self.documentName!)
    }
    //MARK: load bookmark
    func loadBookmarks() -> [String] {
        return UserDefaults.standard.getBookMarks(documentName: self.documentName!)
    }
    //MARK: loads bookmark names
    func loadBookmarkNames() -> [String] {
        
        var bookmarksNameArray: [String]
        let storedBookmarksNames: [String]? = UserDefaults.standard
            .getBookMarkNames(documentName: self.documentName!)
        if storedBookmarksNames != nil {
            bookmarksNameArray = storedBookmarksNames!
        } else {
            bookmarksNameArray = [String]()
            for number in self.bookmarks {
                bookmarksNameArray.append("Page \(number)")
            }
        }
        return bookmarksNameArray
    }
    //MARK: check bookmark exists or not
    func bookmarkExists(page: PDFPage) -> Bool {
        if self.bookmarks.contains(page.label!) {
            return true
        }
        return false
    }
    //MARK: toggle button action function
    func toggleAddButton() {
        self.addButton.isEnabled = !self.bookmarkExists(page: self.currentPage!)
    }
}

//MARK: extension methods for table view data source and delegates
extension PDFBookmarkViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if self.bookmarks.isEmpty {
            self .disableEditing()
        }
        self.editButton.isEnabled = !self.bookmarks.isEmpty
        return self.bookmarks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PDFBookmarkCell = tableView.dequeueReusableCell(withIdentifier: "PDFBookmarkCell",
                                                                  for: indexPath) as! PDFBookmarkCell
        let bookmark: String = self.bookmarkNames[indexPath.row]
        cell.bookmarkTextField.text = bookmark
        cell.bookmarkTextField.tag = indexPath.row
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        if let pageNumber = Int(self.bookmarks[indexPath.row]) {
            self.delegate?.pdfBookmarkViewControllerDidSelect(page: pageNumber)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.bookmarks.remove(at: indexPath.row)
            self.bookmarkNames.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            if self.bookmarks.isEmpty {
                self.disableEditing()
            }
        }
    }
    
    func tableView(_ tableView: UITableView,
                   canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

//MARK: text view delegate extension methods
extension PDFBookmarkViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !self.tableView.isEditing {
            let index = textField.tag
            let pageNumber: Int = Int(self.bookmarkNames[index]) ?? 0
            self.delegate?.pdfBookmarkViewControllerDidSelect(page: pageNumber)
        }
        return self.tableView.isEditing
    }
    
    @IBAction func textFieldEditingChanged(textField: UITextField) {
        let tag = textField.tag
        let range = Range(NSRange(location: tag, length: 1))!
        self.bookmarkNames.replaceSubrange(range, with: [(textField.text ?? "")])
    }
}
