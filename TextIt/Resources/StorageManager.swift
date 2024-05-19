//
//  StorageManager.swift
//  TextIt
//
//  Created by Piyush Pandey on 16/05/24.
//

import FirebaseStorage
import Foundation

final class StorageManager {
    static let shared = StorageManager()
    
    public typealias UploadPicCompletion = (Result<String, Error>) -> Void
    
    private let storage = Storage.storage().reference()
    
    /// Uploads picture to firebase storage and returns url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPicCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metaData, error in
            guard let self else { return }
            guard error == nil else {
                print("Failed to upload the picture!")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { picUrl, error in
                guard let picUrl else {
                    print("Failed to get the download URL!")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = picUrl.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
    
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
}
