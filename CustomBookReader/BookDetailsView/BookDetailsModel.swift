//
//  BookDetailsModel.swift
//
//  Created by Nitin Bhatia on 3/2/21.

//model file 

import UIKit

enum BookType {
    case pdf
    case epub
}

enum BookDetails {
  // MARK: Use cases
  
  enum DownloadBook {
    struct Request {
        var downloadLink: String
        var bookType: BookType
    }
    struct Response {
        var downloadedPath: String
        var bookType: BookType
    }
    struct ViewModel {
    }
  }
}
