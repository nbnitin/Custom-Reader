//
//  PDFReaderInteractor.swift
//
//  Created by Nitin Bhatia on 3/2/21.

import UIKit

protocol PDFReaderBusinessLogic {
    
}

protocol PDFReaderDataStore {
    var destinationFilePath: String? { get set }
}

class PDFReaderInteractor: PDFReaderBusinessLogic, PDFReaderDataStore {
    
    //    var presenter: PDFReaderPresentationLogic?
    //    var worker: PDFReaderWorker?
    var destinationFilePath: String?
    
    // MARK: Do something
}
