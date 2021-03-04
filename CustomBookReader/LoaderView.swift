//
//  LoaderView.swift
//  CustomBookReader
//
//  Created by Nitin Bhatia on 3/2/21.
//

import UIKit

class LoaderView: UIViewController {
    
    @IBOutlet var dotLabel: UILabel!
    @IBOutlet var loadingLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    private var displayLink: CADisplayLink?

    private var loadingLabeltext: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createLoaderView()
        loadingLabel.isHidden = true
        dotLabel.isHidden = true
        dotLabel.text = ""
    }
    
    private func animateLabelDots() {
        guard var text = dotLabel.text else { return }
        text = String(text)
        loadingLabeltext = text
        displayLink = CADisplayLink(target: self, selector: #selector(showHideDots))
        displayLink?.add(to: .main, forMode: .common)
        displayLink?.preferredFramesPerSecond = 1
    }
    
    @objc private func showHideDots() {
        if !loadingLabeltext.contains("...") {
            loadingLabeltext = loadingLabeltext.appending(".")
        } else {
            loadingLabeltext = ""
        }

        dotLabel!.text = loadingLabeltext
    }
    
    func createLoaderView() {
        let imagesArray = [
            UIImage(named: "Loader1")!,
            UIImage(named: "Loader2")!,
            UIImage(named: "Loader3")!,
            UIImage(named: "Loader4")!,
            UIImage(named: "Loader5")!,
            UIImage(named: "Loader6")!,
            UIImage(named: "Loader7")!,
            UIImage(named: "Loader8")!,
            UIImage(named: "Loader9")!,
            UIImage(named: "Loader10")!,
            UIImage(named: "Loader11")!,
            UIImage(named: "Loader12")!]
        imageView.animationImages = imagesArray
        imageView.animationDuration = 1.0
    }
    
    func startAnimating() {
        imageView.startAnimating()
    }
    
    func stopAnimating() {
        imageView.stopAnimating()
    }
    
    func showLoadingLabel(hide:Bool=true) {
        loadingLabel.isHidden = hide
        dotLabel.isHidden = hide
        
        if ( !hide ) {
            animateLabelDots()
        }
    }
}
