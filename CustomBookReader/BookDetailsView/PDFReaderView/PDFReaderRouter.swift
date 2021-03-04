//
//  PDFReaderRouter.swift
///
//  Created by Nitin Bhatia on 3/2/21.

import UIKit

@objc protocol PDFReaderRoutingLogic {
  //func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol PDFReaderDataPassing {
  var dataStore: PDFReaderDataStore? { get }
}

class PDFReaderRouter: NSObject, PDFReaderRoutingLogic, PDFReaderDataPassing {
    //variables
  weak var viewController: PDFReaderViewController?
  var dataStore: PDFReaderDataStore?
  
  // MARK: Routing
  
  //func routeToSomewhere(segue: UIStoryboardSegue?)
  //{
  //  if let segue = segue {
  //    let destinationVC = segue.destination as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //  } else {
  //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
  //    let destinationVC = storyboard.instantiateViewController(withIdentifier: "SomewhereViewController") as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //    navigateToSomewhere(source: viewController!, destination: destinationVC)
  //  }
  //}

  // MARK: Navigation
  
  //func navigateToSomewhere(source: PDFReaderViewController, destination: SomewhereViewController)
  //{
  //  source.show(destination, sender: nil)
  //}
  
  // MARK: Passing data
  
  //func passDataToSomewhere(source: PDFReaderDataStore, destination: inout SomewhereDataStore)
  //{
  //  destination.name = source.name
  //}
}
