//
//  BookDetailsPresenter.swift
///
//  Created by Nitin Bhatia on 3/2/21.
//

//presenter file interacter file interacts with this, this file handles to present book, error view, and loader show and hide

import UIKit

protocol BookDetailsPresentationLogic {
    func presentLoader(show: Bool)
    func presentBook(response: BookDetails.DownloadBook.Response)
    func displayErrorView(failure: AlertResponse, show: Bool)
}

class BookDetailsPresenter: BookDetailsPresentationLogic {
    
    //variable
    weak var viewController: BookDetailsDisplayLogic?
    
    // MARK: Present Book
    func presentBook(response: BookDetails.DownloadBook.Response) {
        self.viewController?.presentBook(response: response)
    }
    
    func presentLoader(show: Bool) {
        self.viewController?.showLoader(show: show)
    }
    
    func displayErrorView(failure: AlertResponse, show: Bool) {
        self.viewController?.displayErrorView(failure: failure, show: true,constraints: [])
    }
}
