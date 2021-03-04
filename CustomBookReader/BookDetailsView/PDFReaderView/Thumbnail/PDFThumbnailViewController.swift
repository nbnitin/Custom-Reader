//
//  PDFThumbnailViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.

import Foundation
import UIKit
import PDFKit

protocol PDFThumbnailViewControllerDelegate: class {
    func pdfThumbnailViewControllerDidSelect(pdfPage: PDFPage)
    func didDismissPdfThumbnailViewController()
}

class PDFThumbnailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    //outlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    //variables
    var pdfDocument: PDFDocument?
    var currentPage: PDFPage?
    private var selectedIndexPath: IndexPath?
    weak var delegate: PDFThumbnailViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.allowsMultipleSelection = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.collectionView.reloadData()
        if let index = self.collectionView.indexPathsForSelectedItems?.first {
            self.collectionView.scrollToItem(at: index,
                                             at: .centeredHorizontally,
                                             animated: false)
        }
    }
    
    //MARK: collection view delegate and data source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.pdfDocument?.pageCount ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PDFThumbnailCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PDFThumbnailCell",
            for: indexPath) as! PDFThumbnailCell
        let pdfPage: PDFPage? = self.pdfDocument?.page(at: indexPath.row)
        if pdfPage != nil {
            let thumbnail = pdfPage!.thumbnail(of: cell.bounds.size,
                                               for: PDFDisplayBox.cropBox)
            cell.thumbnailImageView.image = thumbnail
            cell.pageNumberLabel.text = "\(indexPath.row + 1)"
        }
        if currentPage == pdfPage {
            cell.isHighlighted = true
            self.selectedIndexPath = indexPath
        } else {
            cell.isHighlighted = false
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pdfPage: PDFPage = (self.pdfDocument?.page(at: indexPath.row))!
        self.currentPage = pdfPage
        self.delegate?.pdfThumbnailViewControllerDidSelect(pdfPage: pdfPage)
        self.updateThumbnailCollection(for: indexPath)
    }
    
    func updateThumbnailCollection(for index: IndexPath) {
        var indexPaths: [IndexPath] = [IndexPath]()
        if self.selectedIndexPath != nil {
            indexPaths.append(selectedIndexPath!)
        }
        indexPaths.append(index)
        DispatchQueue.main.async {
            self.collectionView.reloadItems(at: indexPaths)
            if !self.collectionView.indexPathsForVisibleItems.contains(index) {
                self.collectionView.scrollToItem(at: index, at: .centeredVertically, animated: true)
            }
        }
    }
    
    //MARK: closes self
    @IBAction func closeAction(_ sender: Any) {
        self.delegate?.didDismissPdfThumbnailViewController()
    }
}
