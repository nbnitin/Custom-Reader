//
//  PDFThumbnailCell.swift
//
//  Created by Nitin Bhatia on 3/2/21.

import Foundation
import UIKit

class PDFThumbnailCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var roundedView: RoundedView!
    
    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                self.roundedView.layer.backgroundColor = Theme.pdfThumbnailSelectionBackgroundColor.cgColor
                self.pageNumberLabel.textColor = UIColor.orange
            } else {
                self.roundedView.layer.backgroundColor = UIColor.clear.cgColor
                self.pageNumberLabel.textColor = UIColor.white
            }
        }
    }
}
