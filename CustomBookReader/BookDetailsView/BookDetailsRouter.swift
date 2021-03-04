//
//  BookDetailsRouter.swift
//
//  Created by Nitin Bhatia on 3/2/21.
//this file handles the routing

import UIKit

@objc protocol BookDetailsRoutingLogic {
    func routeToDetailsMenuWithSegue(segue: UIStoryboardSegue?)
    func routeToPDFReaderView(filePath: String)
}


class BookDetailsRouter: NSObject, BookDetailsRoutingLogic {
    weak var viewController: BookDetailsViewController?
    
    // MARK: Routing    
    func routeToDetailsMenuWithSegue(segue: UIStoryboardSegue?) {
        if let segue = segue {
            let destinationVC = segue.destination as! DetailsMenuViewController
            
            viewController?.detailMenuViewController = destinationVC
            //destinationVC.inspectable = viewController
        }
    }
    
    func routeToPDFReaderView(filePath: String) {
        if let viewController = self.viewController {
            let destinationVC: PDFReaderViewController = PDFReaderViewController
                .instantiateFromStoryboard(storyboardName: "Main",
                                           storyboardId: "PDFReaderViewController")
            var destinationDS = destinationVC.router!.dataStore!
            destinationVC.parentVC = self.viewController
            destinationDS.destinationFilePath = filePath
            destinationVC.delegateToSetBookName = viewController.detailMenuViewController
            navigateToParentView(source: viewController, destination: destinationVC)
        }
    }
    
   
    
    // MARK: Navigation
    func navigateToParentView(source: BookDetailsViewController, destination: UIViewController) {
        
        destination.willMove(toParent: source)
        source.bookReaderView.addSubview(destination.view)
        source.addChild(destination)
        
        destination.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        destination.view.frame = source.bookReaderView.bounds
        destination.didMove(toParent: source)
    }
    
    
    
}
