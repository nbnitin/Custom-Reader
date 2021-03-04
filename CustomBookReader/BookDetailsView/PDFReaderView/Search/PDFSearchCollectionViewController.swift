//
//  PDFSearchCollectionViewController.swift
///
//  Created by Nitin Bhatia on 3/2/21.

import UIKit
import PDFKit

protocol PDFSearchCollectionViewControllerDelegate: class {
    func pdfSearchCollectionViewControllerDidSelect(pdfPage: PDFPage, selections: [PDFSelection])
}

class PDFSearchCollectionViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    weak var delegate: PDFSearchCollectionViewControllerDelegate?
    
    var searchResults: [PDFPage: [PDFSelection]]? {
        didSet {
            self.selectedIndexPath = nil
            let keys = (searchResults as? NSDictionary)?.allKeys
            self.allPages = keys.map { $0 } as? [PDFPage]
        }
    }
    
    var allPages: [PDFPage]?
    
    var currentPage: PDFPage?
    private var selectedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.allowsMultipleSelection = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.collectionView.reloadData()
        if let index = self.collectionView.indexPathsForSelectedItems?.first {
            self.collectionView.scrollToItem(at: index,
                                             at: .centeredVertically,
                                             animated: false)
        }
    }
}

extension PDFSearchCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.searchResults?.keys.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PDFSearchCollectionViewCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PDFSearchCollectionViewCell",
            for: indexPath) as! PDFSearchCollectionViewCell
        
        if let pdfPage: PDFPage = self.allPages?[indexPath.row] {
            let thumbnail = pdfPage.thumbnail(of: cell.bounds.size,
                                              for: PDFDisplayBox.cropBox)
            cell.thumbnailImageView.image = thumbnail
            if currentPage == pdfPage {
                cell.isHighlighted = true
                self.selectedIndexPath = indexPath
            } else {
                cell.isHighlighted = false
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            if let pdfPage: PDFPage = self.allPages?[indexPath.row] {
                if self.currentPage != pdfPage {
                    self.currentPage = pdfPage
                    self.updateThumbnailCollection(for: indexPath)
                    self.delegate?.pdfSearchCollectionViewControllerDidSelect(pdfPage: pdfPage, selections: self.searchResults?[pdfPage] ?? [])
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 72, height: 94)
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
                self.collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
            }
        }
    }
}

class PDFSearchCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var roundedView: RoundedView!
    
    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                self.roundedView.layer.backgroundColor = Theme.pdfThumbnailSelectionBackgroundColor.cgColor
            } else {
                self.roundedView.layer.backgroundColor = UIColor.clear.cgColor
            }
        }
    }
}
