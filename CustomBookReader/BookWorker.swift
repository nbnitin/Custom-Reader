//
//  BookWorker.swift
//  CustomBookReader
//
//  Created by Nitin Bhatia on 3/2/21.
//

import UIKit

import Foundation

import Alamofire



class Worker {
    
    var dataStore: DataProviderProtocol
    
    init(dataStore: DataProviderProtocol) {
        self.dataStore = dataStore
    }
}


protocol DataProviderProtocol {
    
    var fileService: FileServiceProtocol { get }
    
}

final class RequestInterceptor: Alamofire.RequestInterceptor {}

class ApiStore: DataProviderProtocol {
    
    static let instance = ApiStore()
    
    private var networkService: NetworkServiceWrapper
    private var interceptor: RequestInterceptor
    
    private init() {
        self.interceptor = RequestInterceptor()
        self.networkService = AlamoFireNetworkServiceWrapper(interceptor: interceptor)
    }
    
   
    
   
    
    var fileService: FileServiceProtocol {
        return FileService(networkService: networkService)
    }
    
   
}

class CoreDataStore: DataProviderProtocol {
    
    static let instance = CoreDataStore()
    private init() {}
       
    var fileService: FileServiceProtocol {
        fatalError()
    }
    
}

class MockJsonDataStore: DataProviderProtocol {
    static let instance = MockJsonDataStore()
    private init() {}
    
    var fileService: FileServiceProtocol {
        fatalError()
    }
}


class BookDetailsWorker: Worker {
    
    func downloadBook(request: BookDetails.DownloadBook.Request,
                      completion: @escaping (_ downloadedPath: String?,
                                             _ error: Error?) -> Void) {
        dataStore.fileService.downloadFile(with: request.downloadLink) { (downloadedPath, error) in
            completion(downloadedPath, error)
        }
    }
    
    
}
