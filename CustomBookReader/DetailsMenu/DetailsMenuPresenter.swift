//
//  DetailsMenuPresenter.swift
//
//  Created by Nitin Bhatia on 3/2/21.

//presenter file interacter interacts with this file

import UIKit

protocol DetailsMenuPresentationLogic {    
    func presentLoader(show: Bool)
    func markLike(like: Bool)
}

class DetailsMenuPresenter: DetailsMenuPresentationLogic {
    
    weak var viewController: DetailsMenuDisplayLogic?
    
    // MARK: Do something
    
    func presentLoader(show: Bool) {
        self.viewController?.showLoader(show: show)
    }
    
    func markLike(like: Bool) {
        self.viewController?.markLike(like: like)
    }
}
