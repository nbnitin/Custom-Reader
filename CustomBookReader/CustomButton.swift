//
//  CustomButton.swift
//  CustomBookReader
//
//  Created by Nitin Bhatia on 3/2/21.
//

import Foundation
//
//  CustomButton.swift
//
//  Created by Nitin Bhatia on 3/2/21.

import UIKit

@IBDesignable
class CustomButton: UIButton {
    
    override func awakeFromNib() {
        self.setupView()
    }
    
    @IBInspectable var selectedImageName: String = "" {
        didSet {
            self.setImage(UIImage(named: selectedImageName), for: .selected)
        }
    }
    
    @IBInspectable var normalImageName: String = "" {
        didSet {
            self.setImage(UIImage(named: normalImageName), for: .normal)
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = -1 {
           didSet {
               self.layer.cornerRadius = cornerRadius
           }
       }
    
    override func prepareForInterfaceBuilder() {
            super.prepareForInterfaceBuilder()
            setupView()
        }
    
    func setupView() {
        self.imageView?.contentMode = .scaleAspectFit
        if selectedImageName != "" {
            self.setImage(UIImage(named: selectedImageName), for: .selected)
        }
        if normalImageName != "" {
            self.setImage(UIImage(named: normalImageName), for: .normal)
        }
        if cornerRadius != -1 {
            self.layer.cornerRadius = cornerRadius
        }
        self.layer.cornerRadius = self.frame.height / 2
    }
}

class CustomButtonRightImage: UIButton {
    
    override func awakeFromNib() {
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
        if imageView != nil {
            if AppUtility.isPad() {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: (bounds.width - 35), bottom: 0, right: 5)
            } else {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: (bounds.width - 28), bottom: 0, right: 0)
            }
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: (imageView?.frame.width)!)
        }
    }
}

