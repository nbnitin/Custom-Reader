//
//  BookDetailsViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.
//
//This file is viewcontroller, this controller has interactor, presenter, router and model.
//Interactor interacts with presenter, presenter presents the view accordingly, router redirects from one vc to other, and model handles the data.

import UIKit
import Vision

protocol BookDetailsDisplayLogic: class {
    func showLoader(show: Bool)
    func presentBook(response: BookDetails.DownloadBook.Response)
    func displayErrorView(failure: AlertResponse, show: Bool,constraints:[CGFloat])
}

class BookDetailsViewController: UIViewController, BookDetailsDisplayLogic {
    
    //variables
    var interactor: BookDetailsBusinessLogic?
    var router: (NSObjectProtocol & BookDetailsRoutingLogic)?
    var oldOrientaion : UIInterfaceOrientation!
    var topConstraintConstant : CGFloat!
    var leadingConstraintConstant : CGFloat!
    var trailingConstraintConstant : CGFloat!
    var bottomConstraintConstant : CGFloat!
    var detailMenuViewController : DetailsMenuViewController!
    var bookImage: UIImage?
    var statusBarState = false

    //outlets
    @IBOutlet var bookTitleLabel: UILabel!
    @IBOutlet var roundedView: RoundedView!
    @IBOutlet weak var bookReaderView: UIView!
    @IBOutlet weak var bottomMenuView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet var bookViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var bookViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var bookViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var bookViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var pdfSearchButton: UIButton!
    // MARK: Object lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    
    private func setup() {
        let viewController = self
        let interactor = BookDetailsInteractor()
        let presenter = BookDetailsPresenter()
        let router = BookDetailsRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
    }
    
    // MARK: Routing
    // MARK: this will helps to attach detail menu in bottom
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let scene = segue.identifier {
            let selector = #selector(self.router?.routeToDetailsMenuWithSegue(segue:))
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.closeButton.isHidden = false
        
        //loading actuall pdf view, it first downloads the pdf from given in router's data, and it will load and attach pdfview to this view
        self.loadReaderView()
        
        if AppUtility.isPhone() {
            pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 11, right: 10)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //changing orientation from landscape to portrait, as book always be opened in portrait mode in both iphone and ipad
        oldOrientaion = AppUtility.getCurrentOrientation()
        AppUtility.lockOrientation(.portrait)
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
    }
    
    //MARK: handling constraint and full view here because in iOS 13 or above all constraints handled from code reset to storyboard's value when coming from background. It was creating issue when book is in full view and app goes to background and reopen from background. Then all constraints set to 20 20 and or what ever we set value in storyboard. And in this view will appear also not get called, thats why it is require to do here. Becuase this is being called when app goes to background
    override func viewDidLayoutSubviews() {
        
        //setting constraints accordingly
        if AppUtility.isPhone() {
            topConstraintConstant = 0
            leadingConstraintConstant = 16
            trailingConstraintConstant = 16
            bottomConstraintConstant = 0
        } else {
            topConstraintConstant = 20
            leadingConstraintConstant = 20
            trailingConstraintConstant = 20
            bottomConstraintConstant = 20
        }
        
        fullView(isActivate: statusBarState)
    }
    
    //MARK: status bar state is controlling from here, when book goes to full view then we need to hide status bar as well
    override var prefersStatusBarHidden: Bool{
        return statusBarState
    }
    
    //MARK: activate full view
    func fullView(isActivate:Bool){
        if isActivate {
            bookViewTopConstraint.constant = -(20)
            bookViewLeadingConstraint.constant = 0
            bookViewTrailingConstraint.constant = 0
            bookViewBottomConstraint.constant = -(self.bottomMenuView.frame.height + 20)
        } else {
            bookViewTopConstraint.constant = topConstraintConstant
            bookViewLeadingConstraint.constant = leadingConstraintConstant
            bookViewTrailingConstraint.constant = trailingConstraintConstant
            bookViewBottomConstraint.constant = bottomConstraintConstant
        }
    }
    
    // MARK: Button Actions
    
    //MARK: going back to parent vc, and changing orientation from portraint to landscape
    @IBAction func popViewControllerAction(_ sender: UIButton) {
//        //if AppUtility.isPhone() {
//        AppUtility.lockOrientation(.landscape)
//        AppUtility.lockOrientation(.landscape, andRotateTo: oldOrientaion)
//        // }
//        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: shows the loader
    func showLoader(show: Bool) {
        DispatchQueue.main.async {
            if show {
                self.roundedView.isHidden = false
                self.bottomMenuView.isHidden = true
                self.bookReaderView.startLoading(hideLoadingText: false)
            } else {
                self.bookReaderView.stopLoading()
                self.roundedView.isHidden = true
            }
        }
    }
    
    //MARK: presents book
    func presentBook(response: BookDetails.DownloadBook.Response) {
        DispatchQueue.main.async {
            //self.closeButton.isHidden = false
            self.bottomMenuView.isHidden = false
            switch response.bookType {
            case .pdf:
                self.router?.routeToPDFReaderView(filePath: response.downloadedPath)
            default:
                break
            }
        }
    }
    
    //MARK: download the book
    func loadReaderView() {
        self.interactor?.downloadBook()
    }
    
    //MARK: displays the error view
    func displayErrorView(failure: AlertResponse, show: Bool,constraints:[CGFloat]) {
        self.view.showAlert(alertResponse: failure, delegate: nil,constraints: constraints)
    }
}

//MARK: extension function
extension BookDetailsViewController{
    func alertAction(alertResponse: AlertResponse?) {
        popViewControllerAction(closeButton)
        //self.navigationController?.popViewController(animated: true)
    }
}
