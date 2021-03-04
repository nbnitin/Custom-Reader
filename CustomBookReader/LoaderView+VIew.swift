//
//  LoaderView.swift
//  CustomBookReader
//
//  Created by Nitin Bhatia on 3/2/21.
//

import Foundation
import UIKit

struct AlertWrapper {
    static func showBasicAlert(on vc: UIViewController, with title: String, message: String, completion: @escaping () -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (action) in
            debugPrint("Action")
            completion()
        }
        alert.addAction(action)
        DispatchQueue.main.async {
            vc.present(alert, animated: true)
        }
    }
}

struct Theme {
    static let pdfViewBackgroundColor = UIColor(red: 27/255, green: 30/255, blue: 38/255, alpha: 1)
    static let pdfPageButtonBackgroundColor = UIColor(red: 42/255, green: 45/255, blue: 52/255, alpha: 1)
    static let pdfPageButtonSelectedBackgroundColor = UIColor.orange
    static let pdfThumbnailSelectionBackgroundColor = UIColor(red: 56/255, green: 59/255, blue: 66/255, alpha: 1)
}

var failureView: UIView?
var errorHandlingVC: ErrorHandlingViewController?

protocol AlertHandlingDelegate: class {
    func alertAction(alertResponse: AlertResponse?)
}

extension  AlertHandlingDelegate {
   func alertAction(alertResponse: AlertResponse?) {
    }
}

class ErrorHandlingViewController: UIViewController {
    weak var delegate: AlertHandlingDelegate?
    
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var errorDescriptionLabel: UILabel!
    @IBOutlet weak var errorButton: RoundedButton!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leadingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    var alertResponse: AlertResponse?
    
    var constraints: [NSLayoutConstraint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        constraints = [leadingLayoutConstraint, topLayoutConstraint, trailingLayoutConstraint, bottomLayoutConstraint]
        // Do any additional setup after loading the view.
        errorButton.cornerRadius = errorButton.frame.height / 2
        view.layoutIfNeeded()
    }
    
    private func removeView() {
        self.view.removeFromSuperview()
        self.view = nil
    }
    
    @IBAction func errorButtonAction(_ sender: UIButton) {
        delegate?.alertAction(alertResponse: alertResponse)
        if alertResponse?.alertType == .search {
            return
        }
        removeView()
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        delegate?.alertAction(alertResponse: alertResponse)
        removeView()
    }
    
}


extension UIView {
    
    func showAlert(alertResponse: AlertResponse?, delegate: AlertHandlingDelegate?, constraints: [CGFloat] = [],hideCloseButton:Bool=true) {
        
        DispatchQueue.main.async {
            
            if failureView != nil {
                failureView?.removeFromSuperview();
                failureView = nil
                errorHandlingVC = nil
            }
            
            errorHandlingVC = ErrorHandlingViewController()
            failureView = errorHandlingVC?.view
            
            if failureView != nil {
                errorHandlingVC?.delegate = delegate
                errorHandlingVC?.errorDescriptionLabel.text = alertResponse?.description
                
                errorHandlingVC?.errorButton.isHidden = alertResponse?.alertType == nil
                errorHandlingVC?.closeButton.isHidden = hideCloseButton

                for (index, constraint) in constraints.enumerated() {
                    errorHandlingVC?.constraints[index].constant = constraint
                }
                if alertResponse?.alertType?.rawValue == "" {
                    errorHandlingVC?.errorButton.isHidden = true
                } else {
                    errorHandlingVC?.errorButton.setTitle("Error", for: .normal)
                }
                errorHandlingVC?.alertResponse = alertResponse
                self.addSubview(failureView!)
                failureView?.frame = self.bounds
            }
           
            if alertResponse?.alertType == .share_progress {
               errorHandlingVC?.errorButton.backgroundColor = .darkGray
            } else {
                errorHandlingVC?.alertImageView.stopAnimating()
                let alertResponseCode = alertResponse?.code ?? 0
                
            }
        }
    }
    
    func updateAlert(alertResponse: AlertResponse) {
        DispatchQueue.main.async {
            errorHandlingVC?.errorDescriptionLabel.text = alertResponse.description
            
            errorHandlingVC?.errorButton.isHidden = alertResponse.alertType == nil
            errorHandlingVC?.errorButton.backgroundColor = UIColor(red: 240/255, green: 99/255, blue: 0, alpha: 1)
            errorHandlingVC?.alertImageView.stopAnimating()
            
           
            errorHandlingVC?.errorButton.setTitle(alertResponse.alertType?.rawValue, for: .normal)
            errorHandlingVC?.alertResponse = alertResponse
        }
    }
    func updateTitle(title: String) {
        DispatchQueue.main.async {
            errorHandlingVC?.errorDescriptionLabel.text = title
        }
    }
    
    
    func hideAlert() {
        DispatchQueue.main.async {
            failureView?.removeFromSuperview()
            failureView = nil
            errorHandlingVC = nil
        }
    }
}


struct AppUtility {
    static var oldOrientation : UIInterfaceOrientation!
    static var isAppLocked : Bool = false
    static var isRegisteredPassed : Bool = false
    
    static func getCurrentOrientation()->UIInterfaceOrientation{
        switch UIApplication.shared.statusBarOrientation{
        case .landscapeLeft:
           // self.oldOrientation = .landscapeLeft
            return .landscapeLeft
        case.portrait:
            //self.oldOrientation = .portrait
            return .portrait
        case.portraitUpsideDown:
            //self.oldOrientation = .portraitUpsideDown
            return .portraitUpsideDown
        default:
            //self.oldOrientation = .landscapeRight
            return  .landscapeRight
        }
    }
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
        self.oldOrientation = AppUtility.getCurrentOrientation()
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        self.oldOrientation = AppUtility.getCurrentOrientation()
        self.lockOrientation(orientation)
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    static func isPhone()->Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return true
        }
        return false
    }
    
    static func isPad()->Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }
}



extension UIViewController {
    class func instantiateFromStoryboard(storyboardName: String, storyboardId: String) -> Self {
        return instantiateFromStoryboardHelper(storyboardName: storyboardName, storyboardId: storyboardId)
    }
    
    private class func instantiateFromStoryboardHelper<T>(storyboardName: String, storyboardId: String) -> T {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: storyboardId) as! T
        return controller
    }
    
}

var loaderView: UIView?
var loaderViewController: LoaderView?

//
//  UserDefaults+Extensions.swift
//
//  Created by Nitin Bhatia on 3/2/21.

//this is the extension file handles to save and return data into user defualts

import Foundation

extension UserDefaults {
    
    
   
    
    func getBookMarkNames(documentName: String) -> [String] {
        return UserDefaults.standard.object(
            forKey: "pdf_name_" + documentName) as? [String] ?? [String]()
    }
    
    func saveBookMarkNames(bookmarkNames: [String], documentName: String) {
        UserDefaults.standard.set(bookmarkNames, forKey: "pdf_name_" + documentName)
        UserDefaults.standard.synchronize()
    }
    
    func getBookMarks(documentName: String) -> [String] {
        return UserDefaults.standard.object(
            forKey: "pdf_" + documentName) as? [String] ?? [String]()
    }
    
    func saveBookMarks(bookmarks: [String], documentName: String) {
        UserDefaults.standard.set(bookmarks, forKey: "pdf_" + documentName)
        UserDefaults.standard.synchronize()
    }
    
    struct Keys {
        
        static let bookmark = "bookmark"
       
    }
    
    struct BookmarkResponse: Codable {
        let questionsCount: Int
        let curiousAboutQuestions: [String]

    }

  
    
    var bookmarkResponse: BookmarkResponse? {
        get {
            return  UserDefaults.getDecodedObject(forKey: UserDefaults.Keys.bookmark)
        }
        set(newValue) {
            if newValue == nil {
                removeObject(forKey: UserDefaults.Keys.bookmark)
            } else {
                UserDefaults.saveObject(object: newValue!, forKey: UserDefaults.Keys.bookmark)
            }
        }
    }
    
    
    
    class func saveObject<T: Encodable>(object: T, forKey key: String) {
        let encoder = JSONEncoder()
        let defaults = UserDefaults.standard
        do {
            let  encodedObject = try encoder.encode(object)
            defaults.set(encodedObject, forKey: key)
        } catch {
            debugPrint("Error while Encoding Object for Key: \(key).")
        }
    }
    
    private class func getDecodedObjectsArray<T: Decodable>(forKey key: String) -> [T]? {
        var decodedObjectsArray: [T]?
        let defaults = UserDefaults.standard
        if let bookmarkData = defaults.object(forKey: key) as? Data {
            let decoder = JSONDecoder()
            do {
                decodedObjectsArray = try decoder.decode([T].self, from: bookmarkData)
            } catch {
                debugPrint("Error while Decoding Object Array for Key: \(key).")
            }
        }
        return decodedObjectsArray
    }
    
    private class func getDecodedObject<T: Decodable>(forKey key: String) -> T? {
        var decodedObject: T?
        let defaults = UserDefaults.standard
        if let bookmarkData = defaults.object(forKey: key) as? Data {
            let decoder = JSONDecoder()
            do {
                decodedObject = try decoder.decode(T.self, from: bookmarkData)
            } catch {
                debugPrint("Error while Decoding Object for Key: \(key).")
            }
        }
        return decodedObject
    }
}


extension UIView {
    
    func startLoading(alpha: CGFloat) {
        loaderViewController = LoaderView()
        loaderView = loaderViewController?.view
        DispatchQueue.main.async {
            if loaderView != nil {
                loaderViewController?.backgroundView.alpha = alpha
                loaderViewController?.startAnimating()
                self.addSubview(loaderView!)
               // loaderView?.center = self.center
                loaderView?.frame = self.bounds
            }
        }
    }
    
    func startLoading(hideLoadingText:Bool=true) {
        startLoading(alpha: 0.5)
        loaderViewController?.showLoadingLabel(hide: hideLoadingText)
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            loaderViewController?.stopAnimating()
            loaderViewController?.showLoadingLabel()
            loaderView?.removeFromSuperview()
            loaderView = nil
            loaderViewController = nil
        }
    }
}

struct AlertResponse:Error, Codable {
    var description: String
    let code: Int
    var alertType: AlertType?
}

enum AlertType: String , Codable {
    case pair_device = "Pair Device"
    case search = "Search Again"
    case network_error = "Retry"
    case close, noResultsFound = ""
    case share_progress = "Cancel"
    case share_failure = "Ok"
    case success = "Done"
    static var offline: AlertType { .network_error }
    
  
}

@IBDesignable
class RoundedView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    override func awakeFromNib() {
        self.setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = cornerRadius
    }
}

@IBDesignable
class RoundedButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
            didSet {
                self.layer.cornerRadius = cornerRadius
            }
        }
        
        override func awakeFromNib() {
            self.setupView()
        }
        
        override func prepareForInterfaceBuilder() {
            super.prepareForInterfaceBuilder()
            self.setupView()
        }
        
    func setupView() {
        self.imageView?.contentMode = .scaleAspectFit
        self.layer.cornerRadius = cornerRadius
    }
    
}
