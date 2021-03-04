//
//  SearchController.swift
//
//  Created by Nitin Bhatia on 3/2/21.
//

import UIKit

protocol SearchControllerDelegate: NSObject {
    //func didSelectVoiceSearch()
    func didClose(viewController: UIViewController)
    func didSearch(with textString: String, viewController: UIViewController)
    func justRemoveSearch(viewController: UIViewController)
}

let CLEAR_TEXT_BUTTON_WIDTH_IPAD_PORTRAIT : CGFloat = 30
let CLEAR_TEXT_BUTTON_WIDTH_IPHONE_PORTRAIT : CGFloat = 20

class SearchController: UIViewController {
    
    //outlets
    @IBOutlet var roundedView: RoundedView!
    @IBOutlet var searchButtonContainer: CircleView!
    @IBOutlet weak var textSearchContainerView: UIView!
    @IBOutlet weak var clearTextButton: CustomButton!
    @IBOutlet weak var clearTextButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet var textClearImage: UIImageView!
    
    //variables
    var voiceSearchVC : BookVoiceSearchViewController!
    weak var searchDelegate: SearchControllerDelegate?
    var isVoiceSearchShown : Bool = false
    var previousSearchText : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.becomeFirstResponder()
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        if AppUtility.isPhone() {
            roundedView.cornerRadius = 0
        }
        
        searchTextField.text = previousSearchText
    }
    
    //MARK: clear text button action
    @IBAction func clearTextButtonAction(_ sender: UIButton) {
        self.searchTextField.text = ""
        self.clearTextButtonWidthConstraint.constant = 0
        textClearImage.isHidden = true
    }
    
    //MARK: text field did change
    @objc func textFieldDidChange(_ textField:UITextField) {
        if searchTextField.text!.isEmpty {
            self.clearTextButtonWidthConstraint.constant = 0
            textClearImage.isHidden = true
        }
    }
    
    //MARK: view did layout subview
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchButtonContainer.layer.cornerRadius = searchButtonContainer.frame.width / 2
    }
    
    //MARK: routing to voice search
    @IBAction func textSearchMicButtonAction(_ sender: UIButton) {
        //searchDelegate?.didSelectVoiceSearch()
        if #available(iOS 13.0, *) {
            voiceSearchVC = storyboard?.instantiateViewController(identifier: "bookVoiceSearch") as! BookVoiceSearchViewController
        } else {
            voiceSearchVC = storyboard?.instantiateViewController(withIdentifier: "bookVoiceSearch") as! BookVoiceSearchViewController
        }
        self.searchTextField.resignFirstResponder()
        voiceSearchVC.parentVC = self
        voiceSearchVC.view.frame = self.view.frame
        self.addChild(voiceSearchVC)
        self.view.addSubview(voiceSearchVC.view)
        ((self.parent as? PDFReaderViewController)?.parent as? BookDetailsViewController)?.closeButton.isHidden = true
        isVoiceSearchShown = true
    }
    
    //MARK: removing voice search view
    func removeVoiceSearch(){
        self.voiceSearchVC.removeFromParent()
        self.voiceSearchVC.view.removeFromSuperview()
        ((self.parent as? PDFReaderViewController)?.parent as? BookDetailsViewController)?.closeButton.isHidden = false
        isVoiceSearchShown = false
    }
    
    //MARK: do search
    func doSearch() {
        if let searchText = searchTextField.text, searchText != "" {
            self.searchDelegate?.didSearch(with: searchText, viewController: self)
        } else {
            //Play audio when search text is empty.
        }
    }
    
    //MARK: search button action
    @IBAction func searchButtonAction(_ sender: UIButton) {
        doSearch()
    }
    
    //MARK: close view action
    @IBAction func closeViewControllerAction(_ sender: UIButton) {
        closeSelf()
    }
    
    //MARK: close self
    func closeSelf(){
        if searchTextField.text!.isEmpty {
            searchDelegate?.didClose(viewController: self)
        } else {
            searchDelegate?.justRemoveSearch(viewController: self)
        }
    }
    
    //MARK: touch began action
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if ( isVoiceSearchShown ) {
            return
        }
        
        if let touchedView = touches.first?.view {
            if touchedView != textSearchContainerView || touchedView != searchTextField {
                closeSelf()
            }
        }
    }
}

//MARK: search controller text field delgates
extension SearchController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        debugPrint("In Should change characters Editing")
        if let text = textField.text, !text.isEmpty || !string.isEmpty {
            if AppUtility.isPad() {
                clearTextButtonWidthConstraint.constant = CLEAR_TEXT_BUTTON_WIDTH_IPAD_PORTRAIT
            } else {
                clearTextButtonWidthConstraint.constant = CLEAR_TEXT_BUTTON_WIDTH_IPHONE_PORTRAIT
            }
            textClearImage.isHidden = false
        } else {
            clearTextButtonWidthConstraint.constant = 0
            textClearImage.isHidden = true
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        debugPrint("In Should return ")
        searchTextField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        debugPrint("In textfield clear Editing")
        return false
    }
}
