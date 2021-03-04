//
//  PDFOutlineCell.swift
//
//  Created by Nitin Bhatia on 3/2/21.

//outline custom cell
import Foundation
import UIKit

class PDFOutlineCell: UITableViewCell {
    
    @IBOutlet weak var outlineBackgroundView: RoundedView!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var outlineTextLabel: UILabel!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var leftOffset: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        if self.indentationLevel == 0 {
//            self.outlineTextLabel.font = UIFont.systemFont(ofSize: 15.0)
//        } else {
//            self.outlineTextLabel.font = UIFont.systemFont(ofSize: 14.0)
//        }
//        self.leftOffset.constant = CGFloat(self.indentationLevel * self.indentationLevel)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super .setSelected(selected, animated: animated)
    }
}
