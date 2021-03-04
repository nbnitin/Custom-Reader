//
//  DetailsMenuViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.

//This file is viewcontroller, this controller has interactor, presenter, router and model.
//Interactor interacts with presenter, presenter presents the view accordingly, router redirects from one vc to other, and model handles the data.

import UIKit

protocol DetailsMenuDisplayLogic: class {
    func showLoader(show: Bool)
    func markLike(like: Bool)
}

class DetailsMenuViewController: UIViewController, DetailsMenuDisplayLogic,setPdfTitleProtocol {
    
    
    
    //outlets
    @IBOutlet var bottomBarButtons: [UIButton]!
    
    //MARK: sets book name or title to detail router
    func setBookName(title: String) {
    }
    
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
        let presenter = DetailsMenuPresenter()
        presenter.viewController = viewController
        
    }
   
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setting up view
        for button in bottomBarButtons {
            button.imageView?.contentMode = .scaleAspectFit
            
            if ( button.tag == 2 ) {
                button.setImage(UIImage(named:"unlikeHeart"), for: .normal)
                button.setImage(UIImage(named:"home_bottom_nav_liked_icon"), for: .selected)
            }
        }
        
        
    }
    
    
    
}
//MARK: extension
extension DetailsMenuViewController {
    //MARK: shows loader
    func showLoader(show: Bool) {
        DispatchQueue.main.async {
            if show {
                self.parent?.view.startLoading()
            } else {
                self.parent?.view.stopLoading()
            }
        }
    }
    //MARK: mark like function
    func markLike(like: Bool) {
        DispatchQueue.main.async {
            let likeButton: UIButton? = self.bottomBarButtons.filter { (button) -> Bool in
                return button.tag == 2
            }.first
            
            if like {
                likeButton?.isSelected = true
                //likeButton?.imageEdgeInsets = UIEdgeInsets(top: -15, left: 0, bottom: -10, right: 0)
            } else {
                likeButton?.isSelected = false
                //likeButton?.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
        }
    }
    //MARK: updates the bottom bar
    func updateBottomBar(tag: Int) {
        for button in bottomBarButtons {
            if button.tag == tag {
                button.isSelected = !button.isSelected
                if button.isSelected {
                    button.imageEdgeInsets = UIEdgeInsets(top: -15, left: 0, bottom: -10, right: 0)
                } else {
                    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                }
            }
        }
    }
}
