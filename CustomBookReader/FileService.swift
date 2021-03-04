//
//  FileService.swift
//  CustomBookReader
//
//  Created by Nitin Bhatia on 3/2/21.
//

import Foundation

import Alamofire


protocol APIRouter: URLRequestConvertible {
    
    var method: HTTPMethod { get }
    var endPoint: String { get }
    var parameters: Parameters? { get }
    var baseUrl: String { get }
}

extension APIRouter {
    
    var baseUrl: String {
        return ""
    }
    
    func asURLRequest() throws -> URLRequest {
        let fullURLString = self.baseUrl + endPoint
        let url = try fullURLString.asURL()
        
        var urlRequest = URLRequest(url: url)
        
        // HTTP Method
        urlRequest.httpMethod = method.rawValue
        
//        let authToken = KeyChainServiceWrapper.standard.authToken
//        let bearerToken: String = (authToken ?? "")
        
       
        // Parameters
        if let parameters = parameters {
            do {
                let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
                urlRequest.httpBody = data
            } catch {
                throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
            }
        }
        print("Request : ", urlRequest.description)
        return urlRequest
    }
}


enum FileApiRouter: APIRouter {
    
    case downloadFile(url: String)

    
    var baseUrl: String {
        switch self {
        case .downloadFile(let url):
            return url
        default:
            return ""
        }
    }
    
    // MARK: - HTTPMethod
    var method: HTTPMethod {
        switch self {
        case .downloadFile:
            return .get
        
        }
    }
    // MARK: - Path
    var endPoint: String {
        switch self {
        case .downloadFile:
            return ""
        default:
            return ""
        }
    }
    
    // MARK: - Parameters
    var parameters: Parameters? {
        switch self {
        case .downloadFile:
            return nil
       
        }
    }
}




protocol NetworkServiceWrapper {
    
    
    
    func performDownload(route: APIRouter,
                         completion: @escaping (String?, Error?) -> Void)
    
    
}

protocol NetworkImageServiceWrapper {
    func downloadImage(url: String,
                       completion: @escaping (UIImage?, Error?) -> Void)
}


class BaseService {
    
    var networkService: NetworkServiceWrapper
    
    init(networkService: NetworkServiceWrapper) {
        self.networkService = networkService
    }
}

protocol FileServiceProtocol {
    
    func downloadFile(with url: String, completion: @escaping (String?, Error?) -> Void)
    
}

class FileService: BaseService, FileServiceProtocol {
    
    func downloadFile(with url: String, completion: @escaping (String?, Error?) -> Void) {
        self.networkService
            .performDownload(route: FileApiRouter.downloadFile(url: url)) { (destinationFilePath, error) in
                if error == nil {
                    completion(destinationFilePath, error)
                } else {
                    completion(nil, error)
                }
        }
    }
    
    
}

class AlamoFireNetworkServiceWrapper: NetworkServiceWrapper {
    
    private var interceptor: RequestInterceptor
    
    init(interceptor: RequestInterceptor) {
        self.interceptor = interceptor
    }
    
    
    
    func performDownload(route: APIRouter,
                         completion: @escaping (String?, Error?) -> Void) {
        
        AF.session.configuration.timeoutIntervalForRequest = 180
        var downloadedFilePath: String?
        
        let destination: DownloadRequest.Destination = { temporaryURL, response in
            if let suggestedFileName = response.suggestedFilename {
                do {
                    let directory = try Utils.tempDirectory()
                    downloadedFilePath = (directory + "/" + suggestedFileName)
                    if let downloadedFilePath = downloadedFilePath {
                        if Utils.fileExists(at: downloadedFilePath) {
                            let res = try Utils.deleteFile(at: downloadedFilePath)
                        }
                        return (URL(fileURLWithPath: downloadedFilePath),
                                [.removePreviousFile]) //.createIntermediateDirectories
                    }
                } catch let e {
                }
            }
            
            let (downloadedFileURL, _) = DownloadRequest
                .suggestedDownloadDestination()(temporaryURL, response)
            downloadedFilePath = downloadedFileURL.absoluteString
            return (downloadedFileURL, [.removePreviousFile])//, .createIntermediateDirectories
        }
        
        AF.download(route, to: destination)
            .response { defaultDownloadResponse in
                print(defaultDownloadResponse.result)
                
                let result = defaultDownloadResponse.result
                switch result {
                case .success(let value):
                    if let request = route.urlRequest, let url = request.url {
                        
                    }
                case .failure(let error):
                    completion(nil, error)
                }
                guard let downloadedFilePath = downloadedFilePath else { return }
                completion(downloadedFilePath, nil)
        }
    }
    
}

class Utils {
    
    internal static func fileExists(at path: String) -> Bool {
        
        if !FileManager.default.fileExists(atPath: path) {
            return self .createDirectory(at: path)
        }
        return true
    }
    
    @discardableResult
    internal static func createDirectory(at path: String) -> Bool {
        do {
            try FileManager.default.createDirectory(atPath: path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            return false
        }
        return false
    }
    
    internal static func searchDirectory(with name: String,
                                         in directory: FileManager.SearchPathDirectory) -> String {
        return NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first! + "/" + name
    }
    
    internal static func tempDirectory() throws -> String {
        return try self.directoryInsideDocumentsWithName(name: "temp")
    }
    
    internal static func directoryInsideDocumentsWithName(name: String,
                                                          create: Bool = true) throws -> String {
        let directoryPath = self.searchDirectory(with: name, in: .documentDirectory)
        if create && !self.fileExists(at: directoryPath) {
            self.createDirectory(at: directoryPath)
        }
        return directoryPath
    }
    
    @discardableResult
    internal static func deleteFile(at path: String) throws -> Bool {
        let fileManager = FileManager.default
        if fileManager.isDeletableFile(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
        return false
    }
}
