//
//  PDFPagesViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.
//

//this file helps to control page number display

import UIKit
import PDFKit

protocol PDFPagesViewControllerDelegate: class {
    func pdfPagesViewControllerDidSelect(page: Int)
    func didDismissPdfPagesViewController()
}

class PDFPagesViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    //variable
    weak var delegate: PDFPagesViewControllerDelegate?
    var pdfDocument: PDFDocument?
    var currentPageIndex: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10, execute: {
            let indexpath = IndexPath(row: self.currentPageIndex, section: 0)
            self.tableView.scrollToRow(at: indexpath, at: .middle, animated: true)
        })
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.didDismissPdfPagesViewController()
    }
    
    //MARK: table view data source and delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let lbl = UILabel(frame: tableView.frame)
        lbl.text = "Pages"
        lbl.textAlignment = .center
        lbl.textColor = .white
        lbl.backgroundColor = tableView.backgroundColor
        lbl.font = UIFont(name: "Ubuntu-Regular", size: 20)
        return lbl
    }
   
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pdfDocument?.pageCount ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PDFPagesCell"
        let cell: PDFPagesCell = tableView.dequeueReusableCell(
            withIdentifier: cellIdentifier,
            for: indexPath) as! PDFPagesCell
        let page = self.pdfDocument?.page(at: indexPath.row)
        cell.pageNumberLabel.text = page?.label
        if indexPath.row == currentPageIndex {
            cell.pageBackgroundView.backgroundColor = Theme.pdfPageButtonSelectedBackgroundColor
        } else {
            cell.pageBackgroundView.backgroundColor = UIColor.clear
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.pdfPagesViewControllerDidSelect(page: indexPath.row)
        self.dismiss(animated: true, completion: nil)
    }
}

class PDFPagesCell: UITableViewCell {
    @IBOutlet weak var pageBackgroundView: CircleView!
    @IBOutlet weak var pageNumberLabel: UILabel!
}


@IBDesignable
class CircleView: UIView {
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
}
