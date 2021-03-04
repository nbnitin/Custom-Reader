//
//  BookDetailsInteractor.swift
///
//  Created by Nitin Bhatia on 3/2/21.
//

//this is the interactor file view controller interacts with this file

import UIKit

protocol BookDetailsBusinessLogic {
    func downloadBook()
}


class BookDetailsInteractor: BookDetailsBusinessLogic {
    
    //variables
    var presenter: BookDetailsPresentationLogic?
    var worker: BookDetailsWorker? = BookDetailsWorker(dataStore: ApiStore.instance)
    
    // MARK: Do something
    
    //MARK: download the book
    func downloadBook() {
        getDownloadLink(completion: {urlString in
            guard let pdfDownloadLink = urlString else { return }
            /* sample url to test */
            //let pdfDownloadLink = "http://www.pdf995.com/samples/pdf.pdf"
            /* */
            
            let request = BookDetails.DownloadBook.Request(
                downloadLink: pdfDownloadLink,
                bookType: BookType.pdf)
            self.presenter?.presentLoader(show: true)
            self.worker?.downloadBook(request: request, completion: { (downloadedPath, error) in
                defer {
                    self.presenter?.presentLoader(show: false)
                }
                if error == nil && downloadedPath != nil && !downloadedPath!.isEmpty {
                    self.presenter?.presentBook(response: BookDetails.DownloadBook.Response(
                        downloadedPath: downloadedPath!,
                        bookType: request.bookType))
                } else {
                    self.presenter?.presentLoader(show: false)
                    let alert = AlertResponse(description: "Unable to download Book", code: 1, alertType: .share_failure)
                    self.presenter?.displayErrorView(failure: alert, show: true)
                }
            })
        })
    }
    
    //MARK: get the download url, if book id present. The book id is always be there if book or document not uploaded by parent. The document or book uploaded by parent side doesn't have book id. And in that case we will use content url to download the book else based on condition
    func getDownloadLink(completion:@escaping(_ urlString:String?)->Void) {
        
            completion("http://www.pdf995.com/samples/pdf.pdf")
        //use this link to show error of book not supported
        //https://github.com/nbnitin/Custom-Reader/blob/main/pdf.pdf
    }
}
