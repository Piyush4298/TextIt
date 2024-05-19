//
//  ErrorTypes.swift
//  TextIt
//
//  Created by Piyush Pandey on 19/05/24.
//

import Foundation


public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadUrl
}

public enum DatabaseErrors: Error {
    case failedToFetchUsers
}
