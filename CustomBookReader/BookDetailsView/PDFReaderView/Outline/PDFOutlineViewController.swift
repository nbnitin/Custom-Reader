//
//  PDFOutlineViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.

//this file handles the outline logic

import Foundation
import UIKit
import PDFKit

protocol PDFOutlineViewControllerDelegate: class {
    func pdfOutlineViewControllerDidSelect(pdfOutline: PDFOutline)
    func didDismissPdfOutlineViewController()
}

extension UITableView {

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "Ubuntu", size: 15)
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel
    }

    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}

class PDFOutlineViewController: UITableViewController {
    
    //variables
    var pdfOutlineRoot: PDFOutline?
    var outlineArray: [PDFOutline] = [PDFOutline]()
    var childOutlineArray: [PDFOutline] = [PDFOutline]()
    var currentOutline: PDFOutline?
    private var currentIndexPath: Int = -1
    weak var delegate: PDFOutlineViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let childCount: Int = pdfOutlineRoot?.numberOfChildren ?? 0
        
        for index in 0..<childCount {
            if let pdfOutline: PDFOutline = pdfOutlineRoot?.child(at: index) {
                pdfOutline.isOpen = false
                self.outlineArray.append(pdfOutline)
                if pdfOutline == self.currentOutline {
                    currentIndexPath = index
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.currentIndexPath >= 0 {
            let indexpath = IndexPath(row: self.currentIndexPath, section: 0)
            self.tableView.scrollToRow(at: indexpath, at: .middle, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.didDismissPdfOutlineViewController()
    }
    
    //MARK: table view delegates and data source
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
         let lbl = UILabel(frame: tableView.frame)
         lbl.text = "Content"
         lbl.textAlignment = .center
         lbl.textColor = .white
         lbl.backgroundColor = tableView.backgroundColor
         lbl.font = UIFont(name: "Ubuntu-Bold", size: 20)
         return lbl
     }
    
     override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
         return 80
     }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.outlineArray.count == 0 {
            self.tableView.setEmptyMessage("No content available")
        }
        return self.outlineArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: PDFOutlineCell = tableView.dequeueReusableCell(
            withIdentifier: "PDFOutlineCell", for: indexPath) as! PDFOutlineCell
        
        let pdfOutline = self.outlineArray[indexPath.row]
        cell.outlineTextLabel.text = pdfOutline.label
        cell.pageNumberLabel.text = pdfOutline.destination?.page?.label
        if pdfOutline.numberOfChildren > 0 {
            cell.openButton.setImage( pdfOutline.isOpen ?
                UIImage(named: "arrow_down") : UIImage(named: "arrow_right"),
                                      for: .normal)
            cell.openButton.isEnabled = true
        } else {
            cell.openButton.setImage(nil, for: .normal)
            cell.openButton.isEnabled = false
        }
        cell.openButton.tag = indexPath.row
        cell.openButton.addTarget(self,
                                  action: #selector(self.openButtonAction(sender:)),
                                  for: .touchUpInside)
        
        cell.openButton.tag = indexPath.row
        
        if self.currentOutline == pdfOutline {
            cell.outlineBackgroundView.backgroundColor = Theme.pdfPageButtonSelectedBackgroundColor
        } else {
            cell.outlineBackgroundView.backgroundColor = UIColor.clear
        }
        cell.selectionStyle = .none
        return cell
    }
    
   
    
    //    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    //        let pdfOutline: PDFOutline = self.outlineArray[indexPath.row]
    //        let depth = self.findDepth(pdfOutline: pdfOutline)
    //        return depth
    //    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pdfOutline: PDFOutline = self.outlineArray[indexPath.row]
        self.delegate?.pdfOutlineViewControllerDidSelect(pdfOutline: pdfOutline)
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: open button action
    @objc func openButtonAction(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let row: Int = sender.tag
        let pdfOutline: PDFOutline = self.outlineArray[row]
        if pdfOutline.numberOfChildren > 0 {
            if sender.isSelected {
                pdfOutline.isOpen = true
                self.insertChildfrom(parentOutline: pdfOutline)
            } else {
                pdfOutline.isOpen = false
                self.removeChildFrom(parentOutline: pdfOutline)
            }
            self.tableView.reloadData()
        }
    }
    
    func findDepth(pdfOutline: PDFOutline) -> Int {
        var depth: Int = -1
        var tempOutline: PDFOutline? = pdfOutline
        while tempOutline?.parent != nil {
            depth += 1
            tempOutline = tempOutline?.parent
        }
        return depth
    }
    
    //MARK: setting up outline array
    func insertChildfrom(parentOutline: PDFOutline) {
        self.childOutlineArray.removeAll()
        let baseIndex: Int = (self.outlineArray.firstIndex(of: parentOutline))!
        for index in 0..<parentOutline.numberOfChildren {
            if let pdfOutline: PDFOutline = parentOutline.child(at: index) {
                pdfOutline.isOpen = false
                self.childOutlineArray.append(pdfOutline)
            }
        }
        let indexes: IndexSet = IndexSet(
            integersIn: Range(NSRange(location: baseIndex + 1,
                                      length: self.childOutlineArray.count))!)
        self.outlineArray.insert(contentsOf: self.childOutlineArray, at: indexes.first!)
    }
    
    //MARK: remove view from parent
    func removeChildFrom(parentOutline: PDFOutline) {
        if parentOutline.numberOfChildren <= 0 {
            return
        }
        for index in 0..<parentOutline.numberOfChildren {
            if let pdfOutline: PDFOutline = parentOutline.child(at: index) {
                if pdfOutline.numberOfChildren > 0 {
                    self.removeChildFrom(parentOutline: pdfOutline)
                    if self.outlineArray.contains(pdfOutline) {
                        let index = self.outlineArray.firstIndex(of: pdfOutline)
                        self.outlineArray.remove(at: index!)
                    }
                } else {
                    if self.outlineArray.contains(pdfOutline) {
                        let index = self.outlineArray.firstIndex(of: pdfOutline)
                        self.outlineArray.remove(at: index!)
                    }
                }
            }
        }
    }
}
