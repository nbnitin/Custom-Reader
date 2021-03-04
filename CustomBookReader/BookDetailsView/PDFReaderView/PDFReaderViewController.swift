//
//  PDFReaderViewController.swift
///
//  Created by Nitin Bhatia on 3/2/21.

//this file controls the complete pdf reader view, this file also controls the page view, search router, content router etc...

import UIKit
import PDFKit
import AVFoundation

protocol PDFReaderDisplayLogic: class {
}

protocol setPdfTitleProtocol {
    func setBookName(title:String)
}

//constants
let SECONDS_NO_READABLE_ALERT_REMOVE = 3.0
let PDF_SEARCH_CONTAINER_HEIGHT : CGFloat = 119
let THUMBNAIL_WIDTH_CONSTRAINT_CONSTANT : CGFloat = 140
let THUMBNAIL_TRAILING_CONSTRAINT_CONSTANT : CGFloat = 10

class PDFReaderViewController: UIViewController, PDFReaderDisplayLogic,UIPopoverPresentationControllerDelegate {
    
    //variables
    var delegateToSetBookName : setPdfTitleProtocol!
    var interactor: PDFReaderBusinessLogic?
    var router: (NSObjectProtocol & PDFReaderRoutingLogic & PDFReaderDataPassing)?
    var textToSpeech: TextToSpeechWrapper? = TextToSpeechWrapper.shared
    let animationDuration: TimeInterval = 0.25
    private var currentOutline: PDFOutline?
    private var thumbnailController: PDFThumbnailViewController?
    private var searchResultsController: PDFSearchCollectionViewController?
    private var searchResultArray: [PDFSelection] = [PDFSelection]()
    var searchRe  : [PDFPage: [PDFSelection]] = [PDFPage:[PDFSelection]]()
    var parentVC : BookDetailsViewController!
    var bottomBarButton : UIButton!
    var oldPdfSearchViewContainerHeight : CGFloat = 0
    var nextPage = 0
    var allPages: [PDFPage] = [PDFPage]()
    var pdfViewOldTopConstraintConstant : CGFloat!
    var pdfViewOldBottomConstraintConstant : CGFloat!
    
    //outlets
    @IBOutlet var pdfContentButtonForIphoneForNonSearchMode: UIButton!
    @IBOutlet var pdfContentButttonVIewForIphone: UIButton!
    @IBOutlet var pdfView: PDFView!
    @IBOutlet var pageNumberButtonForIphone: RoundedButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var thumbnailButton: UIButton!
    @IBOutlet weak var pdfTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var searchTextLabel: UILabel!
    @IBOutlet weak var searchTextView: UIStackView!
    @IBOutlet weak var pdfBookButton: UIButton!
    @IBOutlet weak var pdfSearchButton: UIButton!
    @IBOutlet weak var searchResultsView: UIStackView!
    @IBOutlet weak var searchResultsLabel: UILabel!
    @IBOutlet weak var pdfSearchContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var thumbnailContainerView: UIView!
    @IBOutlet weak var thumbnailViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var thumbnailViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var enterFullScreenButton: UIButton!
    @IBOutlet var zoomStackView: UIStackView!
    @IBOutlet var pdfViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var pdfViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var roundedView: RoundedView!
    @IBOutlet var iphonePageAndOutlineStackView: UIStackView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var enterExitFullScreenStackCenterConstraint: NSLayoutConstraint!
    @IBOutlet var enterExitFullScreenStackBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var enterExitFullScreenStackBottomConstraintForIphone: NSLayoutConstraint!
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
        let interactor = PDFReaderInteractor()
        //    let presenter = PDFReaderPresenter()
        let router = PDFReaderRouter()
        viewController.interactor = interactor
        viewController.router = router
        //    interactor.presenter = presenter
        //    presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: Routing
    // MARK: here everything is getting controlled related to segue, outline, search, pagenumber, search thumbnail etc...
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pdfOutlineSegue" {
            let outlineController: PDFOutlineViewController = segue.destination as! PDFOutlineViewController
            outlineController.pdfOutlineRoot = self.pdfView.document?.outlineRoot
            outlineController.delegate = self
            outlineController.currentOutline = self.currentOutline
            
            let popover = outlineController.popoverPresentationController
            
            if AppUtility.isPad() {
                outlineController.preferredContentSize = CGSize(width:500,height:600)
            }
            popover?.delegate = self
            
        } else if segue.identifier == "pdfSearchSegue" {
            let navigationController: UINavigationController = segue.destination as! UINavigationController
            let searchController: PDFSearchViewController = navigationController.viewControllers.first as! PDFSearchViewController
            searchController.pdfDocument = self.pdfView.document
            searchController.delegate = self
        } else if segue.identifier == "pdfThumbnailSegue" {
            let thumbnailController: PDFThumbnailViewController = segue.destination as! PDFThumbnailViewController
            thumbnailController.pdfDocument = self.pdfView.document
            thumbnailController.currentPage = self.pdfView.currentPage
            thumbnailController.delegate = self
            self.thumbnailController = thumbnailController
        } else if segue.identifier == "pdfBookmarkSegue" {
            let navigationController: UINavigationController = segue.destination as! UINavigationController
            let bookMarkViewController: PDFBookmarkViewController = navigationController.viewControllers.first as! PDFBookmarkViewController
            if let filename = self.pdfView.document?.documentURL?.lastPathComponent {
                bookMarkViewController.documentName = filename
            }
            bookMarkViewController.currentPage = self.pdfView.currentPage
            bookMarkViewController.delegate = self
        } else if segue.identifier == "pdfPagesSegue" {
            let pagesController: PDFPagesViewController = segue.destination as! PDFPagesViewController
            pagesController.pdfDocument = self.pdfView.document
            if let currentPage = self.pdfView.currentPage {
                pagesController.currentPageIndex = self.pdfView.document?.index(for: currentPage) ?? 0
            }
            let popover = pagesController.popoverPresentationController
            pagesController.preferredContentSize = CGSize(width:138,height:600)
            popover?.delegate = self
            pagesController.delegate = self
        } else if segue.identifier == "pdfSearchResultsSegue" {
            let searchResultsController: PDFSearchCollectionViewController = segue.destination as! PDFSearchCollectionViewController
            if let currentPage = self.pdfView.currentPage {
                searchResultsController.currentPage = self.pdfView.currentPage
            }
            searchResultsController.delegate = self
            self.searchResultsController = searchResultsController
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setting up view
        addObservers()
        self.setupPDFView()
        self.loadBookView()
        self.thumbnailViewWidthConstraint.constant = 0
        self.pdfSearchContainerHeightConstraint.constant = 0
        bottomBarButton = (parentVC).detailMenuViewController.bottomBarButtons.last!
        bottomBarButton.addTarget(self, action: #selector(readPDF), for: .touchUpInside)
        playPauseButton.isHidden = true
        bottomBarButton.isSelected = false
        bottomBarButton.setImage(UIImage(named:"volumeUp24Px"), for: .normal)
        bottomBarButton.setImage(UIImage(named:"Video_Player_Pause"), for: .selected)
        pdfSearchButton.setImage(UIImage(named:"home_top_nav_search_selected"), for: .selected)
        
        if AppUtility.isPhone() {
            pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 11, right: 10)
        }
        
        pdfContentButttonVIewForIphone.isHidden = true
        pdfContentButtonForIphoneForNonSearchMode.setImage(UIImage(named:"content_selected"), for: .selected)
        pdfContentButttonVIewForIphone.setImage(UIImage(named:"content_selected"), for: .selected)
        
        if enterFullScreenButton != nil {
            enterFullScreenButton.setImage(UIImage(named:"exit_full_screen"), for: .selected)
        }
        
        if pdfViewTopConstraint != nil {
            pdfViewOldTopConstraintConstant = pdfViewTopConstraint.constant
        }
        
        if pdfViewBottomConstraint != nil {
            pdfViewOldBottomConstraintConstant = pdfViewBottomConstraint.constant
        }
    }
       
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        oldPdfSearchViewContainerHeight = pdfSearchContainerHeightConstraint.constant
        
        if let title = router?.dataStore?.destinationFilePath {
            pdfTitleLabel.text = parentVC.bookTitleLabel.text //title.components(separatedBy: "/").last ?? ""
            delegateToSetBookName.setBookName(title: pdfTitleLabel.text!)
        }
        
        nextButton.layer.cornerRadius = nextButton.frame.width / 2
        prevButton.layer.cornerRadius = prevButton.frame.width / 2
        enterFullScreenButton.layer.cornerRadius =  enterFullScreenButton.frame.width / 2
        
        if !thumbnailButton.isHidden {
            thumbnailViewWidthConstraint.constant = 0
        } else {
            thumbnailViewWidthConstraint.constant = THUMBNAIL_WIDTH_CONSTRAINT_CONSTANT
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textToSpeech?.stopSpeaking()
        textToSpeech = nil
        self.playPauseButton.isSelected = false
    }
    
    deinit {
        removeObservers()
    }
    
    //MARK: adding all notification observer require to handler pdf page view changed
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetNavigationButtons),
                                               name: .PDFViewPageChanged, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(update),name: .PDFViewDocumentChanged,object: nil)
    }
    
    //MARK: updating the view
    @objc private func update() {
        // PDF can be zoomed in but not zoomed out
        DispatchQueue.main.async {
            self.pdfView.autoScales = true
            self.pdfView.maxScaleFactor = 4.0
            self.pdfView.minScaleFactor = self.pdfView.scaleFactorForSizeToFit
        }
    }
    
    //MARK: removing observer
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Do something
    
    @IBAction func enterFullButtonAction(_ sender: Any) {
        enterFullScreenButton.isSelected = !enterFullScreenButton.isSelected
        actionForEnterAndExitFullScreen(desicion:enterFullScreenButton.isSelected)
        pdfView.frame = (parentVC).bookReaderView.frame
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
    }
    
    override func viewDidLayoutSubviews() {
        if enterFullScreenButton.isSelected {
            actionForEnterAndExitFullScreen(desicion: enterFullScreenButton.isSelected)
        }
    }
    
    //MARK: toggle between full view and compact view
    private func actionForEnterAndExitFullScreen(desicion:Bool) {
        //enter full screen
        roundedView.isHidden = desicion
        prevButton.isHidden = desicion
        nextButton.isHidden = desicion
        containerView.isHidden = desicion
        (parentVC).bottomMenuView.isHidden = desicion
        (parentVC).closeButton.isHidden = desicion
        (parentVC).statusBarState = desicion
        (parentVC).setNeedsStatusBarAppearanceUpdate()
        (parentVC).fullView(isActivate: desicion)
        zoomStackView.isHidden = desicion
        thumbnailContainerView.isHidden = desicion
        iphonePageAndOutlineStackView.isHidden = desicion
        pdfContentButtonForIphoneForNonSearchMode.isHidden = desicion
        
        if desicion {
            pdfViewBottomConstraint.constant = -(pdfViewOldBottomConstraintConstant)
            pdfViewTopConstraint.constant = -(pdfViewOldTopConstraintConstant)
            searchResultsView.isHidden = true
            thumbnailButton.isHidden = true
            enterExitFullScreenStackCenterConstraint.isActive = false
            
            if AppUtility.isPad() {
                pdfSearchContainerHeightConstraint.constant = 0
                enterExitFullScreenStackBottomConstraint.isActive = true
            } else {
                enterExitFullScreenStackBottomConstraintForIphone.isActive = true
            }
        } else {
            //exit full screen
            pdfViewBottomConstraint.constant = pdfViewOldBottomConstraintConstant
            pdfViewTopConstraint.constant = pdfViewOldTopConstraintConstant
            enterExitFullScreenStackCenterConstraint.isActive = true
            
           if AppUtility.isPhone() {
                enterExitFullScreenStackBottomConstraintForIphone.isActive = false
           } else {
                enterExitFullScreenStackBottomConstraint.isActive = false
           }
            
            if pdfSearchButton.isSelected {
                thumbnailButton.isHidden = true
                searchResultsView.isHidden = false
                pdfContentButtonForIphoneForNonSearchMode.isHidden = true
                pdfContentButttonVIewForIphone.isHidden = false
                
                if AppUtility.isPad() {
                    pdfSearchContainerHeightConstraint.constant = PDF_SEARCH_CONTAINER_HEIGHT
                }
                (self.parentVC).closeButton.isHidden = true
                
            } else {
                if thumbnailViewWidthConstraint.constant > 0 {
                    thumbnailButton.isHidden = true
                    nextButton.isHidden = true
                    prevButton.isHidden = true
                    zoomStackView.isHidden = true
                } else {
                    thumbnailButton.isHidden = false
                    nextButton.isHidden = false
                    prevButton.isHidden = false
                    zoomStackView.isHidden = false
                }
                searchResultsView.isHidden = true
                pdfContentButtonForIphoneForNonSearchMode.isHidden = false
                pdfContentButttonVIewForIphone.isHidden = true
                
                if AppUtility.isPad() {
                    pdfSearchContainerHeightConstraint.constant = 0
                }
                (self.parentVC).closeButton.isHidden = false
            }
        }
    }
    
    //MARK: sets pdf view
    func setupPDFView() {
        pdfView.autoScales = true
        pdfView.enableDataDetectors = true
        pdfView.displayDirection = .horizontal
        self.pdfView.scaleFactor = 1.0
        self.pdfView.displayMode = .singlePage
        self.pdfView.maxScaleFactor = 4.0
        self.pdfView.minScaleFactor = self.pdfView.scaleFactorForSizeToFit
        self.pdfView.usePageViewController(true, withViewOptions: nil)
        self.pdfView.backgroundColor = .clear //Theme.pdfViewBackgroundColor
    }
    
    //MARK: load book view with downloaded book
    func loadBookView() {
        
        if let destinationFilePath = self.router?.dataStore?.destinationFilePath {
            
            //let pdfURL: URL? = Bundle.main.url(forResource: "sample1", withExtension: "pdf")
            let pdfURL: URL? =  NSURL(fileURLWithPath: destinationFilePath) as URL
            
            guard let url = pdfURL else { return }
            let document = PDFDocument(url: url)
            pdfView.frame = (parentVC).bookReaderView.frame
            pdfView.displayMode = .singlePageContinuous
            pdfView.autoScales = true
            pdfView.document = document
            self.thumbnailController?.pdfDocument = document
            
            if document != nil {
                resetNavigationButtons()
            } else {
                //showing error view, if failed to download the book
                let alertResponse = AlertResponse(description: "Book not supported", code: 2, alertType: .share_failure)
                let statusBarHeight = UIApplication.shared.statusBarFrame.height
                self.parentVC.displayErrorView(failure: alertResponse, show: true,constraints: [statusBarHeight,0,statusBarHeight,statusBarHeight])
                self.parentVC.closeButton.isHidden = true
                self.parentVC.bottomMenuView.isHidden = true
                
            }
        }
    }
    
    //MARK: prev button action
    @IBAction func prevAction(_ sender: Any) {
        if AppUtility.isPhone() {
            if ( searchResultArray.count > 0  ) {
                self.goPreviousWithSearch()
            } else {
                self.pdfView.goToPreviousPage(sender)
            }
        } else {
            self.pdfView.goToPreviousPage(sender)
        }
        let tr = CATransition()
        tr.duration = 0.5
        tr.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        tr.type = CATransitionType.init(rawValue: "pageCurl")
        tr.subtype = .fromLeft
        tr.fillMode = .forwards
        tr.fillMode = CAMediaTimingFillMode.forwards
        tr.isRemovedOnCompletion = false
        pdfView.layer.add(tr, forKey: "pageCurlAnimation")
    }
    
    //MARK: play action, it starts reading book
    @IBAction func playAction(_ sender: Any) {
        if let pageContent = pdfView.currentPage?.string {
            self.textToSpeechWithDelgate(text: pageContent, viewController: self)
            textToSpeech?.toggleSpeaking()
            self.playPauseButton.isSelected = !self.playPauseButton.isSelected
        }
    }
    
    //MARK: read pdf
    @objc func readPDF(){
        if let pageContent = pdfView.currentPage?.string, !pageContent.isEmpty, pageContent != " ",pageContent.count > 1 {
            self.textToSpeechWithDelgate(text: pageContent, viewController: self)
            textToSpeech?.toggleSpeaking()
            self.playPauseButton.isSelected = !self.playPauseButton.isSelected
            bottomBarButton.isSelected = !self.bottomBarButton.isSelected
        } else {
            //no content to read out
            let alert = UIAlertController(title: nil, message:NSLocalizedString("no.readable.text", comment: "") , preferredStyle: (AppUtility.isPhone() ? .actionSheet : .alert))
            alert.view.backgroundColor = UIColor.black
            alert.view.alpha = 1
            alert.view.layer.cornerRadius = 15
            self.present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + SECONDS_NO_READABLE_ALERT_REMOVE) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    //MARK: go to next page with search
    private func goNextWithSearch(){
        if ( allPages.count <= 0 ) {
            return
        }
        let pg = allPages[nextPage]
        self.pdfSearchCollectionViewControllerDidSelect(pdfPage: pg,selections: searchRe[pg]!)
        self.nextButton.isEnabled = self.nextPage < self.allPages.count - 1 ? true : false
        self.prevButton.isEnabled = true
        self.nextPage = self.nextPage < self.allPages.count - 1 ? self.nextPage + 1 : self.allPages.count - 1
    }
    
    //MARK: go to previous page with search
    private func goPreviousWithSearch(){
        if self.nextPage == self.allPages.count - 1 {
            self.nextPage -= 1
        }
        if ( nextPage < 0 ) {
            prevButton.isEnabled = false
            return
        }
        let pg = allPages[nextPage]
        self.pdfSearchCollectionViewControllerDidSelect(pdfPage: pg,selections: searchRe[pg]!)
        self.prevButton.isEnabled = self.nextPage < self.allPages.count - 1 ? true : false
        self.nextButton.isEnabled = true
        self.nextPage = self.nextPage < self.allPages.count - 1 ? self.nextPage - 1 : self.allPages.count - 1
        if ( nextPage < 0 ) {
            prevButton.isEnabled = false
            nextPage = 1
        }
    }
    
    //MARK: next action, go to next page
    @IBAction func nextAction(_ sender: Any) {
        if AppUtility.isPhone() {
            if ( searchResultArray.count > 0  ) {
                goNextWithSearch()
            } else {
                self.pdfView.goToNextPage(sender)
            }
        } else {
            self.pdfView.goToNextPage(sender)
        }
        let tr = CATransition()
        tr.duration = 0.5
        tr.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        tr.type = CATransitionType.init(rawValue: "pageCurl")
        tr.subtype = .fromRight
        tr.fillMode = .forwards
        tr.fillMode = CAMediaTimingFillMode.forwards
        tr.isRemovedOnCompletion = false
        pdfView.layer.add(tr, forKey: "pageCurlAnimation")
    }
    
    //MARK: zoom in action
    @IBAction func zoomInAction(_ sender: Any) {
        if self.pdfView.canZoomIn {
            self.pdfView.zoomIn(self)
            self.pdfView.scaleFactor += 0.5
        }
    }
    
    //MARK: zoom out action
    @IBAction func zoomOutAction(_ sender: Any) {
        if self.pdfView.canZoomOut {
            self.pdfView.zoomOut(self)
            
            if self.pdfView.scaleFactor > self.pdfView.scaleFactorForSizeToFit {
                self.pdfView.scaleFactor -= 0.5
            } else {
                self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
            }
        }
    }
    
    //MARK: thumbnail action
    @IBAction func thumbnailAction(_ sender: Any) {
        UIView.animate(withDuration: 2.0, animations: {() in
            if self.thumbnailViewWidthConstraint.constant == 0 {
                self.thumbnailViewWidthConstraint.constant = THUMBNAIL_WIDTH_CONSTRAINT_CONSTANT
                self.thumbnailViewTrailingConstraint.constant = THUMBNAIL_TRAILING_CONSTRAINT_CONSTANT
                self.thumbnailButton.isHidden = true
                self.zoomStackView.isHidden = true
                self.nextButton.isHidden = true
                self.prevButton.isHidden = true
            } else {
                self.thumbnailViewWidthConstraint.constant = 0
                self.thumbnailViewTrailingConstraint.constant = 0
                self.thumbnailButton.isHidden = false
                self.zoomStackView.isHidden = false
                self.nextButton.isHidden = false
                self.prevButton.isHidden = false
            }
            
        })
    }

    //MARK: search button action
    @IBAction func searchAction(_ sender: Any) {
        textToSpeech?.stopSpeaking()
        self.pdfSearchButton.isSelected = !self.pdfSearchButton.isSelected
        setSearchButtonInsets()
        
//        if self.thumbnailButton.isHidden {
//            self.thumbnailAction(thumbnailButton)
//        }
        self.routToSearchView()
    }
    
    //MARK: sets search button insets
    func setSearchButtonInsets(){
        if pdfSearchButton.isSelected {
            if AppUtility.isPhone() {
                pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)
            } else {
                pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: -6, left: -8, bottom: -11, right: -10)
            }
        } else {
            if AppUtility.isPhone() {
                pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                pdfSearchButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 11, right: 10)
            }
        }
    }
    
    //MARK: close search button action
    @IBAction func closeSearchAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.searchTextLabel.text = ""
            self.pdfBookButton.isHidden = false
            self.pdfTitleLabel.isHidden = false
            self.searchTextView.isHidden = true
            self.pdfSearchButton.isSelected = false
            self.searchResultsView.isHidden = true
            self.thumbnailButton.isHidden = false
            self.pdfSearchContainerHeightConstraint.constant = 0
            self.pdfView.highlightedSelections = nil
            self.searchResultsController?.searchResults?.removeAll()
            self.searchResultsController?.collectionView.reloadData()
            self.searchRe.removeAll()
            self.allPages.removeAll()
            self.searchResultArray.removeAll()
            self.nextPage = 0
            self.pdfView.document?.cancelFindString()
            (self.parentVC).closeButton.isHidden = false
            self.pdfContentButttonVIewForIphone.isHidden = true
            self.pdfContentButtonForIphoneForNonSearchMode.isHidden = false
            self.setSearchButtonInsets()
        }
    }
    
    //MARK: pdf contents action
    @IBAction func pdfContentsAction(_ sender: Any) {
        self.pdfContentButttonVIewForIphone.isSelected = !self.pdfContentButttonVIewForIphone.isSelected
        self.pdfContentButtonForIphoneForNonSearchMode.isSelected = !self.pdfContentButtonForIphoneForNonSearchMode.isSelected
        
        if ( self.pdfContentButtonForIphoneForNonSearchMode.isSelected ) {
            self.pdfContentButtonForIphoneForNonSearchMode.imageEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)
        } else {
            self.pdfContentButtonForIphoneForNonSearchMode.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        if ( self.pdfContentButttonVIewForIphone.isSelected ) {
            self.pdfContentButttonVIewForIphone.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        } else {
            self.pdfContentButttonVIewForIphone.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    //MARK: pdf page number action
    @IBAction func pdfPageNumberActions(_ sender: Any) {
        self.pageNumberButtonForIphone.isSelected = !self.pageNumberButtonForIphone.isSelected
        
        if self.pageNumberButtonForIphone.isSelected {
            self.pageNumberButtonForIphone.backgroundColor = Theme.pdfPageButtonSelectedBackgroundColor
        } else {
            self.pageNumberButtonForIphone.backgroundColor = Theme.pdfPageButtonBackgroundColor
        }
    }
    
    //MARK: this helps to show pop over iphones also, as popover is not allowed by default in iphones
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    //MARK: update pdf title and page number
    func updatePdfTitleAndPageNumber() {
        
        if let filename = self.pdfView.document?.documentURL?.lastPathComponent {
            self.pdfTitleLabel.text = filename
        }
        if let currentPageLabel = self.pdfView.currentPage?.label,
           let pageCount = self.pdfView.document?.pageCount {
            self.pageNumberButtonForIphone.setTitle("Page \(currentPageLabel) of \(String(pageCount))", for: .normal)
        }
        self.thumbnailController?.currentPage = self.pdfView.currentPage
    }
    
    //MARK: reset navigation buttons
    @objc func resetNavigationButtons() {
        self.textToSpeech?.stopSpeaking()
        self.playPauseButton.isSelected = false
        
        if ( bottomBarButton != nil ) {
            bottomBarButton.isSelected = false
        }
        self.prevButton.isEnabled = pdfView.canGoToPreviousPage
        self.nextButton.isEnabled = pdfView.canGoToNextPage
        self.updatePdfTitleAndPageNumber()
    }
}

//MARK: pdf reader extension
extension PDFReaderViewController: PDFPagesViewControllerDelegate {
    
    func pdfPagesViewControllerDidSelect(page: Int) {
        if let page = self.pdfView.document?.page(at: page) {
            self.pdfView.go(to: page)
        }
    }
    
    func didDismissPdfPagesViewController() {
        self.pdfPageNumberActions(self.pageNumberButtonForIphone)
        
    }
}

extension PDFReaderViewController: PDFSearchViewControllerDelegate {
    
    func pdfSearchViewControllerDidSelect(pdfSelection: PDFSelection) {
        pdfSelection.color = UIColor.orange
        self.pdfView.go(to: pdfSelection)
        self.pdfView.highlightedSelections = [pdfSelection]
    }
}

extension PDFReaderViewController: PDFOutlineViewControllerDelegate {
    
    func pdfOutlineViewControllerDidSelect(pdfOutline: PDFOutline) {
        self.currentOutline = pdfOutline
        self.pdfView.go(to: (pdfOutline.destination?.page)!)
    }
    
    func didDismissPdfOutlineViewController() {
        
        self.pdfContentButttonVIewForIphone.isSelected = false
        self.pdfContentButtonForIphoneForNonSearchMode.isSelected = false
    }
}

extension PDFReaderViewController: PDFThumbnailViewControllerDelegate {
    func pdfThumbnailViewControllerDidSelect(pdfPage: PDFPage) {
        self.pdfView.go(to: pdfPage)
    }
    
    func didDismissPdfThumbnailViewController() {
        self.thumbnailAction(self.thumbnailButton)
    }
}

extension PDFReaderViewController: PDFBookmarkViewControllerDelegate {
    func pdfBookmarkViewControllerDidSelect(page index: Int) {
        let pdfPage: PDFPage = (self.pdfView.document?.page(at: index-1))!
        self.pdfView.go(to: pdfPage)
    }
}

extension PDFReaderViewController: AVSpeechSynthesizerDelegate {
    
    private func textToSpeechWithDelgate(text: String,
                                         viewController: AVSpeechSynthesizerDelegate) {
        textToSpeech?.configure(string: pdfView.currentPage?.string ?? "")
        textToSpeech?.synthesizer?.delegate = self
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        self.playPauseButton.isSelected = false
        bottomBarButton.isSelected = false
    }
    
    //MARK: this will help to reset speech related when app goes to background, while speech is going on or system reading the content, and opens the app from background
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        self.playPauseButton.isSelected = false
        bottomBarButton.isSelected = false
    }
}

extension PDFReaderViewController {
    
    func routToSearchView() {
        let destinationVC =  SearchController.instantiateFromStoryboard(
            storyboardName: "Main",
            storyboardId: "SearchController")
        destinationVC.searchDelegate = self
        
        if !searchTextLabel.text!.isEmpty {
            destinationVC.previousSearchText = searchTextLabel.text!
        }
        self.parentVC.addChild(destinationVC)
        self.parentVC.view.addSubview(destinationVC.view)
        destinationVC.didMove(toParent: self)
    }
}

extension PDFReaderViewController: SearchControllerDelegate {
    
    //    func didSelectVoiceSearch() {
    //
    //    }
    
    func didSearch(with textString: String, viewController: UIViewController) {
        DispatchQueue.main.async {
            self.pdfBookButton.isHidden = true
            self.pdfTitleLabel.isHidden = true
            self.searchTextView.isHidden = false
            self.searchTextLabel.text = textString
            self.searchResultsView.isHidden = false
            self.thumbnailButton.isHidden = true
            self.removeSearchView(viewController: viewController)
            
            let pdfDocument = self.pdfView.document
            self.searchResultArray.removeAll()
            self.searchResultsController?.searchResults?.removeAll()
            self.searchResultsController?.collectionView.reloadData()
            self.searchResultsLabel.text = "0"
            pdfDocument?.delegate = self
            self.view.startLoading()
            self.nextPage = 0
            pdfDocument?.beginFindString(textString, withOptions: .caseInsensitive)
            (self.parentVC).closeButton.isHidden = true
            self.pdfContentButttonVIewForIphone.isHidden = false
            self.pdfContentButtonForIphoneForNonSearchMode.isHidden = true
        }
    }
    
    func didClose(viewController: UIViewController) {
        self.removeSearchView(viewController: viewController)
        self.pdfSearchButton.isSelected = false
        self.nextButton.isEnabled = true
        self.prevButton.isEnabled = true
        self.setSearchButtonInsets()
    }
    
    func justRemoveSearch(viewController: UIViewController) {
        self.removeSearchView(viewController: viewController)
        self.pdfSearchButton.isSelected = true
        self.setSearchButtonInsets()
    }
    
    func removeSearchView(viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

extension PDFReaderViewController: PDFSearchCollectionViewControllerDelegate {
    
    func pdfSearchCollectionViewControllerDidSelect(pdfPage: PDFPage, selections: [PDFSelection]) {
        self.pdfView.go(to: pdfPage)
        for pdfSelection in selections {
            pdfSelection.color = UIColor.orange
        }
        self.pdfView.highlightedSelections = selections
    }
}

extension PDFReaderViewController: PDFDocumentDelegate {
    
    func didMatchString(_ instance: PDFSelection) {
        print(instance)
        self.searchResultArray.append(instance)
    }
    
    func documentDidEndDocumentFind(_ notification: Notification) {
        DispatchQueue.main.async {
            self.searchResultsController?.currentPage = nil
            self.updateSearchResults()
            self.searchResultsController?.collectionView.reloadData()
            self.view.stopLoading()
        }
    }
    
    func updateSearchResults() {
        self.searchResultsLabel.text = "\(searchResultArray.count)"
        var searchResults: [PDFPage: [PDFSelection]] = [:]
        for selection in searchResultArray {
            if let page = selection.pages.first {
                var results: [PDFSelection]?
                if searchResults.keys.contains(page) {
                    results = searchResults[page]
                } else {
                    results = [PDFSelection]()
                }
                results?.append(selection)
                searchResults[page] = results
            }
        }
        
        
        if AppUtility.isPhone() {
            self.searchRe = searchResults
            let keys = (searchResults as? NSDictionary)?.allKeys
            self.allPages = (keys.map { $0 } as? [PDFPage])!
            
            let _ = self.allPages.sort(by: {
                (self.pdfView.document?.index(for: $0))! < (self.pdfView.document?.index(for: $1))!
            })
            nextPage = 0
            goNextWithSearch()
            self.prevButton.isEnabled = false
            nextPage += 1
            pdfSearchContainerHeightConstraint.constant = 0
        } else {
            if ( searchResults.count == 0 ) {
                pdfSearchContainerHeightConstraint.constant = 0
            } else {
                self.pdfSearchContainerHeightConstraint.constant = PDF_SEARCH_CONTAINER_HEIGHT
            }
            self.searchResultsController?.searchResults = searchResults
        }
    }
}


